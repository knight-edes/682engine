// ShiftRows-like nibble permutation. Forward: out nibble i <- in nibble P[i],
// P = 0 5 10 15 4 9 14 3 8 13 2 7 12 1 6 11. INV=1 gives the inverse. Wires only.
`timescale 1ns/1ps
module prince_sr #(parameter INV = 0) (
    input  wire [63:0] x,
    output wire [63:0] y
);
    // P packed as 16 nibbles, P[0] in the top nibble
    localparam [63:0] P = 64'h05AF_49E3_8D27_C16B;
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : g_sr
            localparam integer SRC = (P >> (60 - 4*i)) & 4'hF;
            if (INV == 0) begin : g_f
                assign y[63-4*i   -: 4] = x[63-4*SRC -: 4];
            end else begin : g_i
                assign y[63-4*SRC -: 4] = x[63-4*i   -: 4];
            end
        end
    endgenerate
endmodule
