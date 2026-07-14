`include "constants.svh"

module pll_generic(
    // from board oscillator
    input  wire clk,
    // clk for the whole system, 25.2 MHz
    output wire system_clk,
    // system_clk x5 (126 MHz) (for HDMI)
    output wire vga_x5,
    // PLL lock
    output wire lock
);

`ifdef TN9K
Gowin_rPLL rPLL(
    .clkout(vga_x5), // output clkout
    .lock(lock),     // output lock
    .clkin(clk)      // input clkin
);

Gowin_CLKDIV clkDIV(
    .clkout(system_clk), // output clkout
    .hclkin(vga_x5),     // input hclkin
    .resetn(lock),       // input resetn
    .calib(1'b1)         // input calib
);
`endif

`ifdef TN20K
Gowin_rPLL rPLL(
    .clkout(vga_x5), // output clkout
    .lock(lock),     // output lock
    .clkin(clk)      // input clkin
);

Gowin_CLKDIV clkDIV(
    .clkout(system_clk), // output clkout
    .hclkin(vga_x5),     // input hclkin
    .resetn(lock),       // input resetn
    .calib(1'b1)         // input calib
);
`endif

`ifdef TP25k
Gowin_PLL rPLL(
   .clkout0(vga_x5), // output clkout
   .lock(lock),      // output lock
   .clkin(clk),      // input clkin
   .mdclk(clk)       // input mdclk
);

Gowin_CLKDIV clkDIV(
    .clkout(system_clk), // output clkout
    .hclkin(vga_x5),     // input hclkin
    .resetn(lock),       // input resetn
    .calib(1'b1)         // input calib
);
`endif

`ifdef SIM
assign system_clk = clk;
assign vga_x5     = 1'b0;
assign lock       = 1'b1;
`endif


endmodule
