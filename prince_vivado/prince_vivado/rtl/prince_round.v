// Forward round R_i:  y = SR(M'(S(x))) ^ RC ^ k
`timescale 1ns/1ps
module prince_round_fwd #(parameter [63:0] RC = 64'h0) (
    input  wire [63:0] x,
    input  wire [63:0] k,
    output wire [63:0] y
);
    wire [63:0] s, m;
    prince_s_layer #(.INV(0)) u_s  (.x(x), .y(s));
    prince_mprime             u_mp (.x(s), .y(m));
    wire [63:0] r;
    prince_sr      #(.INV(0)) u_sr (.x(m), .y(r));
    assign y = r ^ RC ^ k;
endmodule

// Inverse round R_i^-1:  y = S^-1(M'(SR^-1(x ^ k ^ RC)))
`timescale 1ns/1ps
module prince_round_inv #(parameter [63:0] RC = 64'h0) (
    input  wire [63:0] x,
    input  wire [63:0] k,
    output wire [63:0] y
);
    wire [63:0] a = x ^ k ^ RC;
    wire [63:0] r, m;
    prince_sr      #(.INV(1)) u_sr (.x(a), .y(r));
    prince_mprime             u_mp (.x(r), .y(m));
    prince_s_layer #(.INV(1)) u_si (.x(m), .y(y));
endmodule

// Middle (keyless involution):  y = S^-1(M'(S(x)))
`timescale 1ns/1ps
module prince_middle (
    input  wire [63:0] x,
    output wire [63:0] y
);
    wire [63:0] s, m;
    prince_s_layer #(.INV(0)) u_s  (.x(x), .y(s));
    prince_mprime             u_mp (.x(s), .y(m));
    prince_s_layer #(.INV(1)) u_si (.x(m), .y(y));
endmodule
