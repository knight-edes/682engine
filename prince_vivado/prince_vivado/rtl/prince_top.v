// PRINCE encrypt/decrypt engine with one mode input (0 = encrypt, 1 = decrypt).
// Decryption uses alpha-reflection: D(k0,k0',k1) = E(k0',k0,k1 ^ alpha),
// so the mode only drives the key muxes; the datapath is shared.
// Timing: inputs registered on start, core is one combinational stage,
// result registered on the next edge. done and dout are valid one cycle
// after the edge that samples start (2-cycle latency incl. input register).
// Mode is sampled on start, so toggling SW0 mid-block cannot corrupt it.
`timescale 1ns/1ps
module prince_top (
    input  wire        clk,
    input  wire        rst,       // synchronous, active high
    input  wire        start,     // one-cycle pulse
    input  wire        mode,      // must already be synchronised to clk
    input  wire [63:0] din,
    input  wire [63:0] k0,
    input  wire [63:0] k1,
    output reg  [63:0] dout,
    output reg         done
);
    localparam [63:0] ALPHA = 64'hc0ac29b7c97c50dd;

    reg  [63:0] x_r, wpre_r, wpost_r, kc_r;
    reg         busy_r;

    wire [63:0] k0p = {k0[0], k0[63:1]} ^ {63'b0, k0[63]};   // (k0 >>> 1) ^ (k0 >> 63)

    always @(posedge clk) begin
        if (rst) begin
            busy_r <= 1'b0;
            done   <= 1'b0;
        end else begin
            done   <= busy_r;
            busy_r <= start;
            if (start) begin
                x_r     <= din;
                wpre_r  <= mode ? k0p : k0;
                wpost_r <= mode ? k0  : k0p;
                kc_r    <= mode ? (k1 ^ ALPHA) : k1;
            end
        end
    end

    wire [63:0] core_y;
    prince_core u_core (.x(x_r ^ wpre_r), .k1(kc_r), .y(core_y));

    always @(posedge clk) if (busy_r) dout <= core_y ^ wpost_r;
endmodule
