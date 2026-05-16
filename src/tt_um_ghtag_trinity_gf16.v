`default_nettype none
`include "trinity_packet.vh"
// tt_um_ghtag_trinity_gf16 - TinyTapeout top (2x2 neuromorphic SKU)
// Apache-2.0
//
// EULER 2x2 reshape: stripped to core neuromorphic essentials.
// Kept: GF16 mesh, BitNet b1.58 encoder, Crown47 ROM, friend/foe, phi_anchor_post, phi_pll_div.
// Removed: blake3, bpb_counter, alu9_decoder, ring27_memory, multi_tile_receipt,
//           crc32_receipt, hwrng_lfsr, vsa_matmul_8x8/16x16, lucas_rom, trinity_usb3_fifo_bridge,
//           cassini_post, nca_entropy_monitor, plrm_counter, strobe_seed_guard,
//           phi_distance_oracle, trinity_micro_seq, trinity_instr_rom, wb_status_reg, wishbone_full.
//
// Default output: {uio_out, uo_out} == 0x47C0 on reset (canonical anchor).
// Friend/foe handshake on uio[3:0] (EULER constant 8'hAE).

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

    // ---- Legacy combinational dot4 path (preserved — canonical 0x47C0) ----
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

    // ---- Trinity v0 mesh fabric (4-PE GF16 mesh via router) ----
    wire [31:0] host_in_pkt;
    wire        host_in_valid;
    wire        host_in_ready;
    wire [31:0] host_out_pkt;
    wire        host_out_valid;
    wire        host_out_ready;
    wire [15:0] mesh_dbg_tile0;
    wire [15:0] mesh_result;
    wire        mesh_result_valid;
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

    // Router + 4 GF16 tiles
    wire [4*`TRN_PKT_W-1:0] t_pkt_flat;
    wire [3:0]              t_valid;
    wire [3:0]              t_ready;
    wire [4*`TRN_PKT_W-1:0] t_ret_pkt_flat;
    wire [3:0]              t_ret_valid;
    wire [3:0]              t_ret_ready;

    trinity_router_2x2 u_router (
        .clk            (clk),
        .rst_n          (rst_n),
        .host_in_pkt    (host_in_pkt),
        .host_in_valid  (host_in_valid),
        .host_in_ready  (host_in_ready),
        .host_out_pkt   (host_out_pkt),
        .host_out_valid (host_out_valid),
        .host_out_ready (host_out_ready),
        .t_pkt_flat     (t_pkt_flat),
        .t_valid        (t_valid),
        .t_ready        (t_ready),
        .t_ret_pkt_flat (t_ret_pkt_flat),
        .t_ret_valid    (t_ret_valid),
        .t_ret_ready    (t_ret_ready)
    );

    wire [`TRN_PKT_W-1:0] t_in_pkt   [0:3];
    wire [`TRN_PKT_W-1:0] t_out_pkt  [0:3];
    wire [15:0]           tile_dbg   [0:3];

    genvar gi;
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_tile
            assign t_in_pkt[gi] = t_pkt_flat[(gi+1)*`TRN_PKT_W-1 -: `TRN_PKT_W];
            assign t_ret_pkt_flat[(gi+1)*`TRN_PKT_W-1 -: `TRN_PKT_W] = t_out_pkt[gi];

            trinity_gf16_tile #(.TILE_ID(gi[1:0]), .DOT_WIDTH(8)) u_tile (
                .clk        (clk),
                .rst_n      (rst_n),
                .in_pkt     (t_in_pkt[gi]),
                .in_valid   (t_valid[gi]),
                .in_ready   (t_ready[gi]),
                .out_pkt    (t_out_pkt[gi]),
                .out_valid  (t_ret_valid[gi]),
                .out_ready  (t_ret_ready[gi]),
                .dbg_result (tile_dbg[gi])
            );
        end
    endgenerate

    assign mesh_dbg_tile0 = tile_dbg[0];

    // ---- φ-anchor POST (~120 cells — proves φ²+φ⁻²=3 on power-up) ----
    wire phi_ok;
    wire post_done;
    phi_anchor_post u_phi_post (
        .clk(clk), .rst_n(rst_n),
        .phi_ok(phi_ok), .post_done(post_done)
    );

    // ---- phi-PLL fractional divider (~50 cells) ----
    wire phi_tick;
    wire [2:0] phi_state;
    wire phi_div_ok;
    phi_pll_div u_phi_div (
        .clk(clk), .rst_n(rst_n),
        .phi_tick(phi_tick),
        .state(phi_state),
        .phi_div_ok(phi_div_ok)
    );

    // ---- BitNet b1.58 ternary MLP encoder (neuromorphic signature) ----
    reg  [127:0] enc_x;
    reg          enc_start;
    wire         enc_done;
    wire         enc_ok;
    wire [63:0]  enc_y;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enc_x     <= 128'b0;
            enc_start <= 1'b1;
        end else begin
            enc_start <= 1'b0;
        end
    end
    bitnet_encoder u_enc (
        .clk(clk), .rst_n(rst_n),
        .start(enc_start), .x_in(enc_x),
        .done(enc_done), .y_out(enc_y),
        .encoder_ok(enc_ok)
    );

    // ---- TRI NET friend/foe handshake (EULER anchor = 8'hAE) ----
    // uio[0]=tx_bit (OUT), uio[1]=rx_bit (IN), uio[2]=friend, uio[3]=valid
    wire ff_tx;
    wire ff_friend;
    wire ff_valid;
    trinity_friend_foe #(.MY_ANCHOR(8'hAE)) u_friend_foe (
        .clk             (clk),
        .rst_n           (rst_n),
        .rx_bit          (uio_in[1]),
        .tx_bit          (ff_tx),
        .friend_detected (ff_friend),
        .handshake_valid (ff_valid)
    );

    // ---- CROWN47 ROM (~120 cells) ----
    // Activated by uio_in[7]=1 with load_mode=0 (preserves T4 {0x47C0}).
    //   ui_in[6:0]   = crown_addr (0..46)
    //   uio_in[6:5]  = byte_sel (0=mant_lo 1=mant_hi 2=exp 3=tier_flag)
    wire        crown_mode = uio_in[7] && !ui_in[0];
    wire [7:0]  crown_byte_raw;
    crown47_rom_8bit u_crown47 (
        .addr     (ui_in[6:0]),
        .byte_sel (uio_in[6:5]),
        .byte_out (crown_byte_raw)
    );

    // ---- Output mux ----
    // Default: 0x47C0 anchor on reset (final_result = dot_out before mesh done)
    wire [15:0] final_result = mesh_result_valid ? mesh_result : dot_out;

    assign uo_out  = crown_mode ? crown_byte_raw
                                : (final_result[7:0]  | input_echo[7:0]);

    wire [7:0] uio_legacy =
        crown_mode              ? 8'h00 :
        (ui_in[0] && post_done) ? {phi_ok, phi_div_ok, enc_ok, 5'b0} :
                                   (final_result[15:8] | input_echo[15:8]);

    // uio[3:0] = friend/foe; uio[7:4] = legacy
    assign uio_out = {uio_legacy[7:4], ff_valid, ff_friend, 1'b0, ff_tx};
    // uio[1] = RX input; all others output
    assign uio_oe  = 8'b1111_1101;

    // Silence lint: fold all unused signals
    wire _unused = &{1'b0, mesh_dbg_tile0, ena, uio_in,
                     mesh_rcpt_checksum, mesh_rcpt_job_id,
                     mesh_rcpt_tile_id, mesh_rcpt_valid,
                     phi_tick, phi_state,
                     enc_done, enc_y,
                     ui_in[7:4], 1'b0};

endmodule
