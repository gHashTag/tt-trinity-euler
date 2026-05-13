`default_nettype none
// trinity_master_fsm.v - host-side FSM that drives the mesh without any CPU.
// Apache-2.0
//
// On reset release, the FSM auto-issues a canned packet sequence to tile 0:
//   LOAD_A lanes 0..3 with GF16 [1.0, 2.0, 3.0, 4.0]
//   LOAD_B lanes 0..3 with GF16 [1.0, 2.0, 3.0, 4.0]
//   COMPUTE
//   READ_RES
// then latches the returned RESULT into `result_reg` (= 0x47C0 == 30.0 in GF16).
//
// This proves the packet fabric end-to-end (host -> router -> tile -> dot4 -> tile -> router
// -> host) using the existing combinational gf16_dot4 as the tile compute, with NO CPU.
// External pins can later override the canned vectors via a load_mode handshake; v0 just
// boots the demo so the TT test pattern still observes the expected 0x47C0.

`include "trinity_packet.vh"

module trinity_master_fsm (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    ena,
    input  wire                    load_mode, // reserved for future host override

    // To mesh
    output reg  [`TRN_PKT_W-1:0]   host_in_pkt,
    output reg                     host_in_valid,
    input  wire                    host_in_ready,

    input  wire [`TRN_PKT_W-1:0]   host_out_pkt,
    input  wire                    host_out_valid,
    output wire                    host_out_ready,

    // Latched result (RESULT payload from tile 0)
    output reg  [15:0]             result_reg,
    output reg                     result_valid_q
);

    // Canned GF16 operands: 1.0, 2.0, 3.0, 4.0
    function [15:0] gf16_const;
        input [1:0] sel;
        begin
            case (sel)
                2'd0: gf16_const = 16'h3E00; // 1.0
                2'd1: gf16_const = 16'h4000; // 2.0
                2'd2: gf16_const = 16'h4100; // 3.0
                2'd3: gf16_const = 16'h4200; // 4.0
            endcase
        end
    endfunction

    localparam [3:0]
        S_IDLE        = 4'd0,
        S_LOAD_A      = 4'd1,
        S_LOAD_A_WAIT = 4'd2,
        S_LOAD_B      = 4'd3,
        S_LOAD_B_WAIT = 4'd4,
        S_COMPUTE     = 4'd5,
        S_COMPUTE_WT  = 4'd6,
        S_READ        = 4'd7,
        S_READ_WT     = 4'd8,
        S_DONE        = 4'd9;

    reg [3:0] state;
    reg [1:0] lane;

    assign host_out_ready = 1'b1; // always accept return packets

    // Capture RESULT packets addressed to host (any time)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg     <= 16'h0;
            result_valid_q <= 1'b0;
        end else if (host_out_valid && host_out_ready &&
                     (`TRN_PKT_OP(host_out_pkt) == `TRN_OP_RESULT)) begin
            result_reg     <= `TRN_PKT_PAYLOAD(host_out_pkt);
            result_valid_q <= 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            lane          <= 2'd0;
            host_in_pkt   <= {`TRN_PKT_W{1'b0}};
            host_in_valid <= 1'b0;
        end else begin
            // Clear valid on accepted handshake
            if (host_in_valid && host_in_ready)
                host_in_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (ena) begin
                        lane  <= 2'd0;
                        state <= S_LOAD_A;
                    end
                end
                S_LOAD_A: begin
                    host_in_pkt   <= `TRN_MK_PKT(`TRN_OP_LOAD_A, 2'd0, 2'd0,
                                                 {2'd0, lane}, gf16_const(lane));
                    host_in_valid <= 1'b1;
                    state         <= S_LOAD_A_WAIT;
                end
                S_LOAD_A_WAIT: begin
                    if (host_in_ready) begin
                        if (lane == 2'd3) begin
                            lane  <= 2'd0;
                            state <= S_LOAD_B;
                        end else begin
                            lane  <= lane + 2'd1;
                            state <= S_LOAD_A;
                        end
                    end
                end
                S_LOAD_B: begin
                    host_in_pkt   <= `TRN_MK_PKT(`TRN_OP_LOAD_B, 2'd0, 2'd0,
                                                 {2'd0, lane}, gf16_const(lane));
                    host_in_valid <= 1'b1;
                    state         <= S_LOAD_B_WAIT;
                end
                S_LOAD_B_WAIT: begin
                    if (host_in_ready) begin
                        if (lane == 2'd3) begin
                            state <= S_COMPUTE;
                        end else begin
                            lane  <= lane + 2'd1;
                            state <= S_LOAD_B;
                        end
                    end
                end
                S_COMPUTE: begin
                    host_in_pkt   <= `TRN_MK_PKT(`TRN_OP_COMPUTE, 2'd0, 2'd0, 4'h0, 16'h0);
                    host_in_valid <= 1'b1;
                    state         <= S_COMPUTE_WT;
                end
                S_COMPUTE_WT: begin
                    if (host_in_ready)
                        state <= S_READ;
                end
                S_READ: begin
                    host_in_pkt   <= `TRN_MK_PKT(`TRN_OP_READ_RES, 2'd0, 2'd0, 4'h0, 16'h0);
                    host_in_valid <= 1'b1;
                    state         <= S_READ_WT;
                end
                S_READ_WT: begin
                    if (host_in_ready)
                        state <= S_DONE;
                end
                S_DONE: begin
                    // Stay here; result_reg holds the answer.
                    // load_mode would later trigger a re-run from operand pins.
                    if (load_mode) begin
                        // future hook - currently no-op (placeholder)
                        state <= S_DONE;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
