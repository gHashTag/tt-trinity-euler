`default_nettype none

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

    wire [15:0] dot_out;

    wire [15:0] a0, a1, a2, a3;
    wire [15:0] b0, b1, b2, b3;

    assign a0 = 16'h3E00;
    assign a1 = 16'h4000;
    assign a2 = 16'h4100;
    assign a3 = 16'h4200;
    assign b0 = 16'h3E00;
    assign b1 = 16'h4000;
    assign b2 = 16'h4100;
    assign b3 = 16'h4200;

    gf16_dot4 u_dot (
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),
        .result(dot_out)
    );

    assign uo_out  = dot_out[7:0];
    assign uio_out = dot_out[15:8];
    assign uio_oe  = 8'hFF;

    wire _unused = &{ena, clk, rst_n, ui_in, uio_in, 1'b0};

endmodule
