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

    gf16_dot4 u_dot (
        .a0(16'h3E00), .a1(16'h4000), .a2(16'h4100), .a3(16'h4200),
        .b0(16'h3E00), .b1(16'h4000), .b2(16'h4100), .b3(16'h4200),
        .result(dot_out)
    );

    reg [15:0] input_echo;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            input_echo <= 0;
        else if (ena)
            input_echo <= {ui_in, uio_in};
    end

    assign uo_out  = dot_out[7:0]  | input_echo[7:0];
    assign uio_out = dot_out[15:8] | input_echo[15:8];
    assign uio_oe  = 8'hFF;

endmodule
