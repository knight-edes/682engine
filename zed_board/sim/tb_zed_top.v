// Testbench for zed_top (MMCM bypassed, short debounce and BIST).
// Presses buttons like a user and checks the LEDs.
`timescale 1ns/1ps
module tb_zed_top;
    reg        gclk = 0, btnc = 0, btnr = 0, btnl = 0, btnu = 0;
    reg  [7:0] sw = 8'h00;
    wire [7:0] led;
    integer    errors = 0, v, m, b;

    zed_top #(.SIM(1), .DEB_BITS(3), .BIST_LOG2N(8), .HB_BIT(4)) dut (
        .gclk(gclk), .btnc(btnc), .btnr(btnr), .btnl(btnl), .btnu(btnu), .sw(sw), .led(led));
    always #20 gclk = ~gclk;     // 25 MHz (MMCM bypassed)

    reg [63:0] PT [0:4], CT [0:4];
    initial begin
        PT[0]=64'h0000000000000000; CT[0]=64'h818665aa0d02dfda;
        PT[1]=64'hffffffffffffffff; CT[1]=64'h604ae6ca03c20ada;
        PT[2]=64'h0000000000000000; CT[2]=64'h9fb51935fc3df524;
        PT[3]=64'h0000000000000000; CT[3]=64'h78a54cbe737bb7ef;
        PT[4]=64'h0123456789abcdef; CT[4]=64'hae25ad3ca8fa9ccf;
    end

    task press_c; begin btnc = 1; repeat (40) @(posedge gclk); btnc = 0; repeat (40) @(posedge gclk); end endtask
    task press_l; begin btnl = 1; repeat (40) @(posedge gclk); btnl = 0; repeat (40) @(posedge gclk); end endtask
    task press_r; begin btnr = 1; repeat (40) @(posedge gclk); btnr = 0; end endtask
    task expect_led(input [7:0] mask, input [7:0] val, input [255:0] what);
        begin
            repeat (4) @(posedge gclk);
            if ((led & mask) !== (val & mask)) begin
                errors = errors + 1;
                $display("FAIL %0s: led=%b expected %b (mask %b)", what, led, val, mask);
            end
        end
    endtask

    reg [63:0] expv;
    initial begin
        btnu = 1; repeat (10) @(posedge gclk); btnu = 0; repeat (10) @(posedge gclk);

        // ---- every KAT, both modes: status LEDs and all 8 result bytes ----
        for (v = 0; v < 5; v = v + 1)
            for (m = 0; m < 2; m = m + 1) begin
                sw = {1'b0, 3'd0, v[2:0], m[0]};
                repeat (4) @(posedge gclk);
                press_c;
                expect_led(8'b1100_0010, {2'b10, 4'b0, m[0], 1'b0}, "KAT status");
                expv = m ? PT[v] : CT[v];
                for (b = 0; b < 8; b = b + 1) begin
                    sw = {1'b1, b[2:0], v[2:0], m[0]};
                    expect_led(8'hFF, expv[63 - 8*b -: 8], "KAT byte");
                end
                $display("[KAT %0d %s] ok so far, errors=%0d", v, m ? "dec" : "enc", errors);
            end

        // ---- negative KAT: index 1 with mode bit wrong is impossible from the switches,
        //      so check the FAIL LED via BIST fault injection instead ----
        sw = 8'h00;
        press_r;
        wait (led[3] == 1'b1);                      // busy
        wait (led[3] == 1'b0);                      // finished
        expect_led(8'b0011_1100, 8'b0010_0000, "BIST pass");
        $display("[BIST] clean run: led=%b", led);

        press_l;                                    // fault on
        expect_led(8'b0000_0100, 8'b0000_0100, "fault LED on");
        press_r;
        wait (led[3] == 1'b1);
        wait (led[3] == 1'b0);
        expect_led(8'b0011_1100, 8'b0001_0100, "BIST fail with fault");
        $display("[BIST] fault-injected run: led=%b", led);

        press_l;                                    // fault off, BIST passes again
        press_r;
        wait (led[3] == 1'b1);
        wait (led[3] == 1'b0);
        expect_led(8'b0011_1100, 8'b0010_0000, "BIST pass after fault off");

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("TESTS FAILED: %0d errors", errors);
        $finish;
    end
endmodule
