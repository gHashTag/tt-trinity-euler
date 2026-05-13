`default_nettype none
// boards/qmtech_a100t/sync_reset_n.v
// Apache-2.0
//
// 4-stage active-low reset synchronizer. Asserts asynchronously, deasserts
// synchronously to `clk`. Pure ready/valid plumbing helper, no arithmetic.

module sync_reset_n (
    input  wire clk,
    input  wire async_rst_n,
    output wire sync_rst_n
);
    (* ASYNC_REG = "TRUE" *) reg [3:0] sync_ff;

    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) sync_ff <= 4'b0000;
        else              sync_ff <= {sync_ff[2:0], 1'b1};
    end

    assign sync_rst_n = sync_ff[3];
endmodule
