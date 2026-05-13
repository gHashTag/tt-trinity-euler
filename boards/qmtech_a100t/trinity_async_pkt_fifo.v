`default_nettype none
// boards/qmtech_a100t/trinity_async_pkt_fifo.v
// Apache-2.0
//
// Classic gray-code asynchronous FIFO for 32-bit Trinity packets, used as a
// CDC bridge between the ft_clk (100 MHz, FT601) and trn_clk (50 MHz, Trinity
// fabric) domains in `top_usb3_loopback.v`.
//
// Hard rules:
//   - No multipliers. Only counters, gray-code, and dual-port BRAM-inferred
//     memory.
//   - No vendor IP. Pure portable Verilog so openXC7 / Vivado / iverilog can
//     all build it.
//   - This file is NOT instantiated by the TT die; TT GDS does not need CDC.
//
// References:
//   * Clifford E. Cummings, "Simulation and Synthesis Techniques for Asynchronous
//     FIFO Design" (SNUG 2002). Standard gray-pointer scheme.
//
// Depth = 1 << DEPTH_LOG2 entries; DEPTH_LOG2 = 4 -> 16 packets default.

`include "../../src/trinity_packet.vh"

module trinity_async_pkt_fifo #(
    parameter DEPTH_LOG2 = 4
) (
    // ---- Write side ----
    input  wire                    wr_clk,
    input  wire                    wr_rst_n,
    input  wire [`TRN_PKT_W-1:0]   wr_pkt,
    input  wire                    wr_valid,
    output wire                    wr_ready,    // == !full

    // ---- Read side ----
    input  wire                    rd_clk,
    input  wire                    rd_rst_n,
    output wire [`TRN_PKT_W-1:0]   rd_pkt,
    output wire                    rd_valid,    // == !empty
    input  wire                    rd_ready
);

    localparam AW = DEPTH_LOG2;
    localparam DEPTH = (1 << AW);

    // Memory (inferred as dual-port BRAM by typical synthesis tools)
    reg [`TRN_PKT_W-1:0] mem [0:DEPTH-1];

    // Pointers: binary + gray code, each domain owns its own
    reg [AW:0] wbin, wgray;
    reg [AW:0] rbin, rgray;

    // Cross-domain synchronizers
    (* ASYNC_REG = "TRUE" *) reg [AW:0] wgray_sync0, wgray_sync1; // sampled in rd_clk
    (* ASYNC_REG = "TRUE" *) reg [AW:0] rgray_sync0, rgray_sync1; // sampled in wr_clk

    function [AW:0] bin2gray;
        input [AW:0] b;
        bin2gray = b ^ (b >> 1);
    endfunction

    // ---- Write side ----
    wire        do_write = wr_valid && wr_ready;
    wire [AW:0] wbin_next  = wbin + {{AW{1'b0}}, do_write};
    wire [AW:0] wgray_next = bin2gray(wbin_next);

    // Full when next write gray equals (synced read gray) with two MSBs inverted
    wire full = (wgray_next == {~rgray_sync1[AW:AW-1], rgray_sync1[AW-2:0]});
    assign wr_ready = ~full;

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wbin  <= {AW+1{1'b0}};
            wgray <= {AW+1{1'b0}};
            rgray_sync0 <= {AW+1{1'b0}};
            rgray_sync1 <= {AW+1{1'b0}};
        end else begin
            // sync read gray pointer into write domain
            rgray_sync0 <= rgray;
            rgray_sync1 <= rgray_sync0;

            if (do_write) begin
                mem[wbin[AW-1:0]] <= wr_pkt;
                wbin  <= wbin_next;
                wgray <= wgray_next;
            end
        end
    end

    // ---- Read side ----
    wire        do_read    = rd_valid && rd_ready;
    wire [AW:0] rbin_next  = rbin + {{AW{1'b0}}, do_read};
    wire [AW:0] rgray_next = bin2gray(rbin_next);

    // Empty when read gray equals synced write gray
    wire empty = (rgray == wgray_sync1);
    assign rd_valid = ~empty;
    assign rd_pkt   = mem[rbin[AW-1:0]];

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rbin  <= {AW+1{1'b0}};
            rgray <= {AW+1{1'b0}};
            wgray_sync0 <= {AW+1{1'b0}};
            wgray_sync1 <= {AW+1{1'b0}};
        end else begin
            // sync write gray pointer into read domain
            wgray_sync0 <= wgray;
            wgray_sync1 <= wgray_sync0;

            if (do_read) begin
                rbin  <= rbin_next;
                rgray <= rgray_next;
            end
        end
    end

endmodule
