// ZedBoard hardware test harness for the unpipelined PRINCE engine.
//
// Controls
//   SW0      : mode for the known-answer test (0 = encrypt, 1 = decrypt)
//   SW3..SW1 : test-vector index 0..4 (Appendix A of ePrint 2012/529); 5..7 -> 4
//   SW6..SW4 : byte select for the byte view (0 = dout[63:56] ... 7 = dout[7:0])
//   SW7      : LED view (0 = status, 1 = selected byte of the last KAT result)
//   BTNC     : run the selected known-answer test (KAT) once
//   BTNR     : run the built-in self-test (BIST): 2^BIST_LOG2N random blocks,
//              each encrypted then decrypted (mode switched in hardware), compared
//   BTNL     : toggle fault injection (flips bit 0 of k1 for the BIST decrypt only)
//   BTNU     : reset
//
// Status view (SW7 = 0)
//   LD7 KAT pass   LD6 KAT fail   LD5 BIST pass   LD4 BIST fail
//   LD3 BIST busy  LD2 fault on   LD1 mode of last KAT   LD0 heartbeat (~1.5 Hz)
//
// Clock: 100 MHz GCLK -> MMCM -> 25 MHz (unpipelined core needs ~24-30 ns).
`timescale 1ns/1ps
module zed_top #(
    parameter SIM        = 0,    // 1: bypass the MMCM (simulation only)
    parameter DEB_BITS   = 18,   // debounce: 2^18 clocks ~ 10.5 ms at 25 MHz
    parameter BIST_LOG2N = 20,   // BIST length: 2^20 = 1,048,576 blocks
    parameter HB_BIT     = 23    // heartbeat LED: counter bit (25 MHz / 2^24 ~ 1.5 Hz)
)(
    input  wire       gclk,      // Y9, 100 MHz
    input  wire       btnc, btnr, btnl, btnu,
    input  wire [7:0] sw,
    output reg  [7:0] led
);
    // ---------------- clocking and reset ----------------
    wire clk, locked;
    generate
        if (SIM) begin : g_simclk
            assign clk = gclk; assign locked = 1'b1;
        end else begin : g_mmcm
            wire fb, clk_mmcm;
            MMCME2_BASE #(
                .CLKIN1_PERIOD   (10.0),   // 100 MHz in
                .DIVCLK_DIVIDE   (1),
                .CLKFBOUT_MULT_F (8.0),    // VCO = 800 MHz
                .CLKOUT0_DIVIDE_F(32.0)    // 800 / 32 = 25 MHz
            ) u_mmcm (
                .CLKIN1(gclk), .CLKFBIN(fb), .CLKFBOUT(fb),
                .CLKOUT0(clk_mmcm), .LOCKED(locked),
                .RST(1'b0), .PWRDWN(1'b0),
                .CLKOUT0B(), .CLKOUT1(), .CLKOUT1B(), .CLKOUT2(), .CLKOUT2B(),
                .CLKOUT3(), .CLKOUT3B(), .CLKOUT4(), .CLKOUT5(), .CLKOUT6(), .CLKFBOUTB());
            BUFG u_bufg (.I(clk_mmcm), .O(clk));
        end
    endgenerate

    // reset: held while MMCM unlocked, plus BTNU (synchronised, not debounced:
    // any press resets, bounce only resets again)
    (* ASYNC_REG = "TRUE" *) reg [1:0] rst_s = 2'b11;
    reg rst = 1'b1;
    always @(posedge clk) begin
        rst_s <= {rst_s[0], (~locked) | btnu};
        rst   <= rst_s[1];
    end

    // ---------------- inputs ----------------
    (* ASYNC_REG = "TRUE" *) reg [7:0] sw_a, sw_s;
    always @(posedge clk) begin sw_a <= sw; sw_s <= sw_a; end

    wire c_lvl, c_rise, r_lvl, r_rise, l_lvl, l_rise;
    debounce #(.CNT_BITS(DEB_BITS)) u_dbc (.clk(clk), .rst(rst), .din(btnc), .level(c_lvl), .rise(c_rise));
    debounce #(.CNT_BITS(DEB_BITS)) u_dbr (.clk(clk), .rst(rst), .din(btnr), .level(r_lvl), .rise(r_rise));
    debounce #(.CNT_BITS(DEB_BITS)) u_dbl (.clk(clk), .rst(rst), .din(btnl), .level(l_lvl), .rise(l_rise));

    // ---------------- known-answer vectors: pt, k0, k1, ct ----------------
    wire [2:0] idx = (sw_s[3:1] > 3'd4) ? 3'd4 : sw_s[3:1];
    reg  [63:0] v_pt, v_k0, v_k1, v_ct;
    always @* begin
        case (idx)
            3'd0: begin v_pt = 64'h0000000000000000; v_k0 = 64'h0000000000000000; v_k1 = 64'h0000000000000000; v_ct = 64'h818665aa0d02dfda; end
            3'd1: begin v_pt = 64'hffffffffffffffff; v_k0 = 64'h0000000000000000; v_k1 = 64'h0000000000000000; v_ct = 64'h604ae6ca03c20ada; end
            3'd2: begin v_pt = 64'h0000000000000000; v_k0 = 64'hffffffffffffffff; v_k1 = 64'h0000000000000000; v_ct = 64'h9fb51935fc3df524; end
            3'd3: begin v_pt = 64'h0000000000000000; v_k0 = 64'h0000000000000000; v_k1 = 64'hffffffffffffffff; v_ct = 64'h78a54cbe737bb7ef; end
            default: begin v_pt = 64'h0123456789abcdef; v_k0 = 64'h0000000000000000; v_k1 = 64'hfedcba9876543210; v_ct = 64'hae25ad3ca8fa9ccf; end
        endcase
    end

    // ---------------- engine ----------------
    reg         e_start, e_mode;
    reg  [63:0] e_din, e_k0, e_k1;
    wire [63:0] e_dout;
    wire        e_done;
    prince_top u_prince (.clk(clk), .rst(rst), .start(e_start), .mode(e_mode),
                         .din(e_din), .k0(e_k0), .k1(e_k1), .dout(e_dout), .done(e_done));

    // ---------------- xorshift64 generators for the BIST ----------------
    function [63:0] xs64; input [63:0] x; reg [63:0] t;
        begin t = x ^ (x << 13); t = t ^ (t >> 7); xs64 = t ^ (t << 17); end
    endfunction
    reg [63:0] g_p, g_k0, g_k1;

    // ---------------- control FSM ----------------
    localparam S_IDLE = 3'd0, S_KAT = 3'd1, S_BENC = 3'd2, S_BENCW = 3'd3,
               S_BDEC = 3'd4, S_BDECW = 3'd5;
    reg [2:0]  st;
    reg [63:0] res, exp_kat, b_p, b_c;
    reg        kat_valid, kat_pass, kat_mode;
    reg        bist_busy, bist_done, bist_fail, fault;
    reg [BIST_LOG2N-1:0] b_cnt;

    always @(posedge clk) begin
        e_start <= 1'b0;
        if (rst) begin
            st <= S_IDLE; kat_valid <= 1'b0; kat_pass <= 1'b0; kat_mode <= 1'b0;
            bist_busy <= 1'b0; bist_done <= 1'b0; bist_fail <= 1'b0; fault <= 1'b0;
            res <= 64'd0;
            g_p <= 64'h9e3779b97f4a7c15; g_k0 <= 64'hbf58476d1ce4e5b9; g_k1 <= 64'h94d049bb133111eb;
        end else begin
            if (l_rise && st == S_IDLE) fault <= ~fault;
            case (st)
            S_IDLE:
                if (c_rise) begin                       // one known-answer test
                    e_mode  <= sw_s[0];  kat_mode <= sw_s[0];
                    e_din   <= sw_s[0] ? v_ct : v_pt;
                    exp_kat <= sw_s[0] ? v_pt : v_ct;
                    e_k0 <= v_k0; e_k1 <= v_k1; e_start <= 1'b1;
                    st <= S_KAT;
                end else if (r_rise) begin              // BIST
                    bist_busy <= 1'b1; bist_done <= 1'b0; bist_fail <= 1'b0;
                    b_cnt <= 0; st <= S_BENC;
                end
            S_KAT:
                if (e_done) begin
                    res <= e_dout; kat_pass <= (e_dout == exp_kat); kat_valid <= 1'b1;
                    st <= S_IDLE;
                end
            S_BENC: begin                               // encrypt random block
                b_p <= g_p;
                e_mode <= 1'b0; e_din <= g_p; e_k0 <= g_k0; e_k1 <= g_k1; e_start <= 1'b1;
                st <= S_BENCW;
            end
            S_BENCW:
                if (e_done) begin b_c <= e_dout; st <= S_BDEC; end
            S_BDEC: begin                               // decrypt it (same keys)
                e_mode <= 1'b1; e_din <= b_c; e_k1 <= e_k1 ^ {63'd0, fault}; e_start <= 1'b1;
                st <= S_BDECW;
            end
            S_BDECW:
                if (e_done) begin
                    if (e_dout != b_p || b_c == b_p) bist_fail <= 1'b1;
                    g_p <= xs64(g_p); g_k0 <= xs64(g_k0); g_k1 <= xs64(g_k1);
                    b_cnt <= b_cnt + 1'b1;
                    if (&b_cnt) begin
                        bist_busy <= 1'b0; bist_done <= 1'b1; st <= S_IDLE;
                    end else st <= S_BENC;
                end
            default: st <= S_IDLE;
            endcase
        end
    end

    // ---------------- LEDs ----------------
    reg [HB_BIT:0] hb = 0;
    always @(posedge clk) hb <= hb + 1'b1;
    wire [7:0] status = {kat_valid & kat_pass, kat_valid & ~kat_pass,
                         bist_done & ~bist_fail, bist_done & bist_fail,
                         bist_busy, fault, kat_mode, hb[HB_BIT]};
    wire [7:0] byte_v = res[63 - 8*sw_s[6:4] -: 8];
    always @(posedge clk) led <= sw_s[7] ? byte_v : status;
endmodule
