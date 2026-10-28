// 2-FF synchroniser + counter debouncer for one mechanical input.
// level : debounced level; rise : one-cycle pulse on a debounced 0->1 edge.
// The input must be stable for 2^CNT_BITS clocks to be accepted
// (CNT_BITS = 18 at 25 MHz -> ~10.5 ms).
`timescale 1ns/1ps
module debounce #(parameter CNT_BITS = 18) (
    input  wire clk,
    input  wire rst,
    input  wire din,      // raw, asynchronous
    output reg  level,
    output reg  rise
);
    (* ASYNC_REG = "TRUE" *) reg s0, s1;
    reg [CNT_BITS-1:0] cnt;
    always @(posedge clk) begin
        s0 <= din; s1 <= s0;
        rise <= 1'b0;
        if (rst) begin
            level <= 1'b0; cnt <= 0;
        end else if (s1 == level) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1'b1;
            if (&cnt) begin
                level <= s1;
                rise  <= s1;          // pulse only on the rising edge
            end
        end
    end
endmodule
