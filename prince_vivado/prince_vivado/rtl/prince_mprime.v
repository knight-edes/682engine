// M' layer: 64x64 binary involution, block-diagonal (M^0, M^1, M^1, M^0) over
// four 16-bit chunks. Inside a chunk, output nibble j, bit t (t=0 = nibble MSB):
//   y(j,t) = XOR over input nibbles k != kx of x(k,t),   kx = (t - j - off) mod 4
// with off = 0 for M^0 (chunks 0,3) and 1 for M^1 (chunks 1,2).
// Each output bit is a 3-input XOR -> one LUT on 7-series.
`timescale 1ns/1ps
module prince_mprime (
    input  wire [63:0] x,
    output wire [63:0] y
);
    genvar b, j, t, k;
    generate
        for (b = 0; b < 4; b = b + 1) begin : g_chunk
            localparam integer OFF = (b == 0 || b == 3) ? 0 : 1;
            for (j = 0; j < 4; j = j + 1) begin : g_nib
                for (t = 0; t < 4; t = t + 1) begin : g_bit
                    localparam integer KX = (t - j - OFF + 8) % 4;
                    wire [3:0] col;  // bit t of the 4 input nibbles of this chunk
                    for (k = 0; k < 4; k = k + 1) begin : g_col
                        assign col[k] = x[63 - (16*b + 4*k + t)];
                    end
                    assign y[63 - (16*b + 4*j + t)] = ^(col & ~(4'b0001 << KX));
                end
            end
        end
    endgenerate
endmodule
