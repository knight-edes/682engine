// 16 parallel S-boxes. Nibble 0 = x[63:60] (most-significant), nibble 15 = x[3:0].
`timescale 1ns/1ps
module prince_s_layer #(parameter INV = 0) (
    input  wire [63:0] x,
    output wire [63:0] y
);
    genvar n;
    generate
        for (n = 0; n < 16; n = n + 1) begin : g_sb
            prince_sbox #(.INV(INV)) u_sb (.x(x[63-4*n -: 4]), .y(y[63-4*n -: 4]));
        end
    endgenerate
endmodule
