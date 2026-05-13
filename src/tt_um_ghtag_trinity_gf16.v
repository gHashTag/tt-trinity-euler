`default_nettype none
// tt_um_ghtag_trinity_gf16 - TinyTapeout top.
// Apache-2.0
//
// v0 Trinity mesh-computer top: instantiates trinity_mesh_2x2 (4 GF16 tiles + crossbar
// router) plus a CPU-less master FSM that issues a canned packet sequence to tile 0.
//
// Backward compatibility: the existing testbench checks {uio_out, uo_out} == 0x47C0
// immediately after reset. The combinational gf16_dot4 of the canned vectors remains
// instantiated and drives the outputs by default; the mesh FSM result overrides only
// once it asserts result_valid_q (so the new mesh path is exercised on the same pins
// after a few extra cycles, observable by a longer-waiting testbench).

module tt_um_ghtag_trinity_gf16 (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ---- Legacy combinational dot4 path (preserved) ----
    wire [15:0] dot_out;
    gf16_dot4 u_dot (
        .a0(16'h3E00), .a1(16'h4000), .a2(16'h4100), .a3(16'h4200),
        .b0(16'h3E00), .b1(16'h4000), .b2(16'h4100), .b3(16'h4200),
        .result(dot_out)
    );

    // Input echo (legacy)
    reg [15:0] input_echo;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            input_echo <= 0;
        else if (ena)
            input_echo <= {ui_in, uio_in};
    end

    // ---- New: Trinity v0 mesh fabric ----
    wire [31:0] host_in_pkt;
    wire        host_in_valid;
    wire        host_in_ready;
    wire [31:0] host_out_pkt;
    wire        host_out_valid;
    wire        host_out_ready;
    wire [15:0] mesh_dbg_tile0;
    wire [15:0] mesh_result;
    wire        mesh_result_valid;
    // G4 DePIN on-die receipt outputs from the master FSM (latched RECEIPT packet)
    wire [7:0]  mesh_rcpt_checksum;
    wire [7:0]  mesh_rcpt_job_id;
    wire [1:0]  mesh_rcpt_tile_id;
    wire        mesh_rcpt_valid;

    trinity_master_fsm u_master (
        .clk             (clk),
        .rst_n           (rst_n),
        .ena             (ena),
        .load_mode       (ui_in[0]),
        .host_in_pkt     (host_in_pkt),
        .host_in_valid   (host_in_valid),
        .host_in_ready   (host_in_ready),
        .host_out_pkt    (host_out_pkt),
        .host_out_valid  (host_out_valid),
        .host_out_ready  (host_out_ready),
        .result_reg      (mesh_result),
        .result_valid_q  (mesh_result_valid),
        .rcpt_checksum_q (mesh_rcpt_checksum),
        .rcpt_job_id_q   (mesh_rcpt_job_id),
        .rcpt_tile_id_q  (mesh_rcpt_tile_id),
        .rcpt_valid_q    (mesh_rcpt_valid)
    );

    trinity_mesh_2x2 u_mesh (
        .clk             (clk),
        .rst_n           (rst_n),
        .host_in_pkt     (host_in_pkt),
        .host_in_valid   (host_in_valid),
        .host_in_ready   (host_in_ready),
        .host_out_pkt    (host_out_pkt),
        .host_out_valid  (host_out_valid),
        .host_out_ready  (host_out_ready),
        .dbg_tile0_result(mesh_dbg_tile0)
    );

    // Output mux: combinational dot result by default, mesh result once produced.
    wire [15:0] final_result = mesh_result_valid ? mesh_result : dot_out;

    assign uo_out  = final_result[7:0]  | input_echo[7:0];
    assign uio_out = final_result[15:8] | input_echo[15:8];
    assign uio_oe  = 8'hFF;

    // Silence lint on unused. The G4 receipt outputs are exposed to the
    // testbench via the master FSM directly (not via TT pins, which are
    // exhausted by the legacy dot4/mesh result mux); they MUST be folded
    // into _unused here so synthesis keeps the registers.
    wire _unused = &{1'b0, mesh_dbg_tile0, ena,
                     mesh_rcpt_checksum, mesh_rcpt_job_id,
                     mesh_rcpt_tile_id, mesh_rcpt_valid, 1'b0};

endmodule
