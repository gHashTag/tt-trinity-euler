`default_nettype none
// sim/g1_loopback/ft601_fifo_model.v
// Apache-2.0
//
// Behavioural model of an FT601 in 245-synchronous FIFO mode, just enough for
// the G1 loopback testbench. NOT a Linux driver, NOT a USB-3 PHY — it only
// emulates the FPGA-facing pins:
//   * `ft_rxf_n` goes low when a word the PC pushed is available to the FPGA
//   * `ft_txe_n` goes low when the FT601 has space for FPGA-sent words
//   * `ft_rd_n` from the FPGA pops one word per cycle
//   * `ft_wr_n` from the FPGA pushes one word per cycle
//   * `ft_data[31:0]` is bidirectional; we drive it when `ft_oe_n` is low (read)
//
// Two internal FIFOs:
//   PC -> FPGA queue: filled by `push` task in the TB, read by FPGA via RD#.
//   FPGA -> PC queue: filled by FPGA via WR#, drained by `pop_ack` from TB.

module ft601_fifo_model (
    input  wire        clk,
    input  wire        rst_n,

    // ---- TB-side push (PC -> FPGA queue) ----
    input  wire        push,
    input  wire [31:0] push_word,
    output wire        push_full,

    // ---- TB-side pop (FPGA -> PC queue) ----
    output wire        pop_valid,
    output wire [31:0] pop_word,
    input  wire        pop_ack,

    // ---- FT601 pins facing the DUT ----
    output wire        ft_rxf_n,
    output wire        ft_txe_n,
    input  wire        ft_rd_n,
    input  wire        ft_wr_n,
    input  wire        ft_oe_n,
    inout  wire [31:0] ft_data
);

    // ---- PC -> FPGA queue (host_in path) ----
    localparam IN_DEPTH = 64;
    reg [31:0] in_mem [0:IN_DEPTH-1];
    reg [6:0]  in_wptr, in_rptr;
    wire       in_empty = (in_wptr == in_rptr);
    wire       in_full  = ((in_wptr - in_rptr) == IN_DEPTH);

    assign push_full = in_full;
    assign ft_rxf_n  = in_empty;     // active low: low == data available

    wire       do_rd = (~ft_rd_n) && (~ft_oe_n) && !in_empty;
    wire [31:0] in_head = in_mem[in_rptr[5:0]];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_wptr <= 7'd0;
            in_rptr <= 7'd0;
        end else begin
            if (push && !in_full) begin
                in_mem[in_wptr[5:0]] <= push_word;
                in_wptr <= in_wptr + 7'd1;
            end
            if (do_rd) begin
                in_rptr <= in_rptr + 7'd1;
            end
        end
    end
    // Drive ft_data combinationally from the FIFO head when DUT asserts OE# low.
    // This matches FT601 behaviour: when OE# is asserted, the current head of
    // the chip's internal FIFO is presented on the bus; RD# pops it on the next
    // rising edge of clk.
    assign ft_data = (~ft_oe_n) ? in_head : 32'hzzzzzzzz;

    // ---- FPGA -> PC queue (host_out path) ----
    localparam OUT_DEPTH = 64;
    reg [31:0] out_mem [0:OUT_DEPTH-1];
    reg [6:0]  out_wptr, out_rptr;
    wire       out_empty = (out_wptr == out_rptr);
    wire       out_full  = ((out_wptr - out_rptr) == OUT_DEPTH);

    assign ft_txe_n  = out_full;       // active low: low == space available
    assign pop_valid = ~out_empty;
    assign pop_word  = out_mem[out_rptr[5:0]];

    wire do_wr = (~ft_wr_n) && !out_full;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_wptr <= 7'd0;
            out_rptr <= 7'd0;
        end else begin
            if (do_wr) begin
                out_mem[out_wptr[5:0]] <= ft_data;
                out_wptr <= out_wptr + 7'd1;
            end
            if (pop_ack && !out_empty) begin
                out_rptr <= out_rptr + 7'd1;
            end
        end
    end

endmodule
