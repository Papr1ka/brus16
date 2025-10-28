//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11.03 Education
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Sun Oct 26 21:15:09 2025

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
defparam prom_inst_0.INIT_RAM_00 = 256'h000D3C34C1203C2103C154792208428C10008C0120004210002070A0050320D0;
defparam prom_inst_0.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000000000000100003;

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
defparam prom_inst_1.INIT_RAM_00 = 256'h00020C08C0000C0000C0C0000108428C01000000000400000100080280000240;
defparam prom_inst_1.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000000020000200001;

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
defparam prom_inst_2.INIT_RAM_00 = 256'h00030C0CC0000C0000C00010000003000000000000C000000000100100000003;
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
defparam prom_inst_3.INIT_RAM_00 = 256'h00010C04C0000C0000C00000000401400000000000C000001000100100080001;
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
defparam prom_inst_4.INIT_RAM_00 = 256'h00080C02800008000080288A2A2088280220088022888022122008A88AAA8022;
defparam prom_inst_4.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000080020000200002;

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
defparam prom_inst_5.INIT_RAM_00 = 256'h82004A01E0420E0420E012048481201E048812204826204809880E14E15E0C1F;
defparam prom_inst_5.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000020468204782046;

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
defparam prom_inst_6.INIT_RAM_00 = 256'h4924212A1221212212120100404010A120448112040112042044A906904C4493;
defparam prom_inst_6.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000052254922549225;

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
defparam prom_inst_7.INIT_RAM_00 = 256'h5D7671781771717717179164545917817455D157450157453055E156155D6797;
defparam prom_inst_7.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000057705D7705D770;

endmodule //Gowin_pROM
