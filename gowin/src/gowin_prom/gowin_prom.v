//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11.03 Education
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Sat Oct 18 16:15:07 2025

module Gowin_pROM (dout, clk, oce, ce, reset, ad);

output [15:0] dout;
input clk;
input oce;
input ce;
input reset;
input [12:0] ad;

wire [29:0] prom_inst_0_dout_w;
wire [29:0] prom_inst_1_dout_w;
wire [29:0] prom_inst_2_dout_w;
wire [29:0] prom_inst_3_dout_w;
wire [29:0] prom_inst_4_dout_w;
wire [29:0] prom_inst_5_dout_w;
wire [29:0] prom_inst_6_dout_w;
wire [29:0] prom_inst_7_dout_w;
wire gw_gnd;

assign gw_gnd = 1'b0;

pROM prom_inst_0 (
    .DO({prom_inst_0_dout_w[29:0],dout[1:0]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({ad[12:0],gw_gnd})
);

defparam prom_inst_0.READ_MODE = 1'b0;
defparam prom_inst_0.BIT_WIDTH = 2;
defparam prom_inst_0.RESET_MODE = "SYNC";
defparam prom_inst_0.INIT_RAM_00 = 256'h0038F0E30480F0840F06512488310F30400230048001084000810284140CC440;
defparam prom_inst_0.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000000000001000030;

pROM prom_inst_1 (
    .DO({prom_inst_1_dout_w[29:0],dout[3:2]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({ad[12:0],gw_gnd})
);

defparam prom_inst_1.READ_MODE = 1'b0;
defparam prom_inst_1.BIT_WIDTH = 2;
defparam prom_inst_1.RESET_MODE = "SYNC";
defparam prom_inst_1.INIT_RAM_00 = 256'h00083023000030000303004004210A3004000000001000000400600A00000A00;
defparam prom_inst_1.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000000200002000010;

pROM prom_inst_2 (
    .DO({prom_inst_2_dout_w[29:0],dout[5:4]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({ad[12:0],gw_gnd})
);

defparam prom_inst_2.READ_MODE = 1'b0;
defparam prom_inst_2.BIT_WIDTH = 2;
defparam prom_inst_2.RESET_MODE = "SYNC";
defparam prom_inst_2.INIT_RAM_00 = 256'h000C3033000030000300004000000C000000000003000000000040040000000C;
defparam prom_inst_2.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000000000000000000;

pROM prom_inst_3 (
    .DO({prom_inst_3_dout_w[29:0],dout[7:6]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({ad[12:0],gw_gnd})
);

defparam prom_inst_3.READ_MODE = 1'b0;
defparam prom_inst_3.BIT_WIDTH = 2;
defparam prom_inst_3.RESET_MODE = "SYNC";
defparam prom_inst_3.INIT_RAM_00 = 256'h0004301300003000030000000010050000000000030000004000400400200004;
defparam prom_inst_3.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000000000000000000;

pROM prom_inst_4 (
    .DO({prom_inst_4_dout_w[29:0],dout[9:8]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({ad[12:0],gw_gnd})
);

defparam prom_inst_4.READ_MODE = 1'b0;
defparam prom_inst_4.BIT_WIDTH = 2;
defparam prom_inst_4.RESET_MODE = "SYNC";
defparam prom_inst_4.INIT_RAM_00 = 256'h00A0300A000020000200A228A88220A0088022008A220088488022A22AAA008A;
defparam prom_inst_4.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000800200002000020;

pROM prom_inst_5 (
    .DO({prom_inst_5_dout_w[29:0],dout[11:10]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({ad[12:0],gw_gnd})
);

defparam prom_inst_5.READ_MODE = 1'b0;
defparam prom_inst_5.BIT_WIDTH = 2;
defparam prom_inst_5.RESET_MODE = "SYNC";
defparam prom_inst_5.INIT_RAM_00 = 256'h30912C07C10C3C10C3C04C131304C07C13304CC1309CC13027303C63C67910BE;
defparam prom_inst_5.INIT_RAM_01 = 256'h00000000000000000000000000000000000000000000000007046C3047C3046C;

pROM prom_inst_6 (
    .DO({prom_inst_6_dout_w[29:0],dout[13:12]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({ad[12:0],gw_gnd})
);

defparam prom_inst_6.READ_MODE = 1'b0;
defparam prom_inst_6.BIT_WIDTH = 2;
defparam prom_inst_6.RESET_MODE = "SYNC";
defparam prom_inst_6.INIT_RAM_00 = 256'h921084A848848488484804010100428481120448100448108112A41A4131224C;
defparam prom_inst_6.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000522549225492254;

pROM prom_inst_7 (
    .DO({prom_inst_7_dout_w[29:0],dout[15:14]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({ad[12:0],gw_gnd})
);

defparam prom_inst_7.READ_MODE = 1'b0;
defparam prom_inst_7.BIT_WIDTH = 2;
defparam prom_inst_7.RESET_MODE = "SYNC";
defparam prom_inst_7.INIT_RAM_00 = 256'hD759C5E05DC5C5DC5C5E459151645E05D157455D14055D14C157855855759E5D;
defparam prom_inst_7.INIT_RAM_01 = 256'h000000000000000000000000000000000000000000000000057705D7705D7705;

endmodule //Gowin_pROM
