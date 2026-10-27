// PRINCE 4-bit S-box (INV=0) or its inverse (INV=1).
// Bit 3 of x/y is the most-significant bit of the nibble.
`timescale 1ns/1ps
module prince_sbox #(parameter INV = 0) (
    input  wire [3:0] x,
    output reg  [3:0] y
);
    always @* begin
        if (INV == 0) begin
            case (x)  // S = B F 3 2 A C 9 1 6 7 8 0 E 5 D 4
                4'h0: y = 4'hB; 4'h1: y = 4'hF; 4'h2: y = 4'h3; 4'h3: y = 4'h2;
                4'h4: y = 4'hA; 4'h5: y = 4'hC; 4'h6: y = 4'h9; 4'h7: y = 4'h1;
                4'h8: y = 4'h6; 4'h9: y = 4'h7; 4'hA: y = 4'h8; 4'hB: y = 4'h0;
                4'hC: y = 4'hE; 4'hD: y = 4'h5; 4'hE: y = 4'hD; default: y = 4'h4;
            endcase
        end else begin
            case (x)  // S^-1 = B 7 3 2 F D 8 9 A 6 4 0 5 E C 1
                4'h0: y = 4'hB; 4'h1: y = 4'h7; 4'h2: y = 4'h3; 4'h3: y = 4'h2;
                4'h4: y = 4'hF; 4'h5: y = 4'hD; 4'h6: y = 4'h8; 4'h7: y = 4'h9;
                4'h8: y = 4'hA; 4'h9: y = 4'h6; 4'hA: y = 4'h4; 4'hB: y = 4'h0;
                4'hC: y = 4'h5; 4'hD: y = 4'hE; 4'hE: y = 4'hC; default: y = 4'h1;
            endcase
        end
    end
endmodule
