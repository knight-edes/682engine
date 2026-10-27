// PRINCEcore, fully unrolled and purely combinational (12 S-layers).
`timescale 1ns/1ps
module prince_core (
    input  wire [63:0] x,
    input  wire [63:0] k1,
    output wire [63:0] y
);
    localparam [63:0] RC0  = 64'h0000000000000000, RC1  = 64'h13198a2e03707344,
                      RC2  = 64'ha4093822299f31d0, RC3  = 64'h082efa98ec4e6c89,
                      RC4  = 64'h452821e638d01377, RC5  = 64'hbe5466cf34e90c6c,
                      RC6  = 64'h7ef84f78fd955cb1, RC7  = 64'h85840851f1ac43aa,
                      RC8  = 64'hc882d32f25323c54, RC9  = 64'h64a51195e0e3610d,
                      RC10 = 64'hd3b5a399ca0c2399, RC11 = 64'hc0ac29b7c97c50dd;

    wire [63:0] s0 = x ^ k1 ^ RC0;
    wire [63:0] s1, s2, s3, s4, s5, sm, s6, s7, s8, s9, s10;
    prince_round_fwd #(.RC(RC1))  r1  (.x(s0), .k(k1), .y(s1));
    prince_round_fwd #(.RC(RC2))  r2  (.x(s1), .k(k1), .y(s2));
    prince_round_fwd #(.RC(RC3))  r3  (.x(s2), .k(k1), .y(s3));
    prince_round_fwd #(.RC(RC4))  r4  (.x(s3), .k(k1), .y(s4));
    prince_round_fwd #(.RC(RC5))  r5  (.x(s4), .k(k1), .y(s5));
    prince_middle                 mid (.x(s5), .y(sm));
    prince_round_inv #(.RC(RC6))  r6  (.x(sm), .k(k1), .y(s6));
    prince_round_inv #(.RC(RC7))  r7  (.x(s6), .k(k1), .y(s7));
    prince_round_inv #(.RC(RC8))  r8  (.x(s7), .k(k1), .y(s8));
    prince_round_inv #(.RC(RC9))  r9  (.x(s8), .k(k1), .y(s9));
    prince_round_inv #(.RC(RC10)) r10 (.x(s9), .k(k1), .y(s10));
    assign y = s10 ^ k1 ^ RC11;
endmodule
