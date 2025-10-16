//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11.03 Education
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Thu Oct 16 22:37:40 2025

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
defparam prom_inst_0.INIT_RAM_00 = 256'h00000000103417007104CF380281200091630C20820104C3F00210324C4220D0;

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
defparam prom_inst_1.INIT_RAM_00 = 256'h000000000030010011040C04114111044160000004100010C001110004C10240;

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
defparam prom_inst_2.INIT_RAM_00 = 256'h0000000000100200000004000000000000000000000000004000000000000003;

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
defparam prom_inst_3.INIT_RAM_00 = 256'h0000000000100100020004000000020000020020000200004200000000080001;

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
defparam prom_inst_4.INIT_RAM_00 = 256'h000000002088A88AA208822822822208A2A208208A2208A22202AAAAAA0A8022;

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
defparam prom_inst_5.INIT_RAM_00 = 256'h000000001307187197C042C4CC5CC7C04C67C07C04C7C05C27C19999590E442F;

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
defparam prom_inst_6.INIT_RAM_00 = 256'h00000000110116901342014044044342041342342043420413484444012D4893;

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
defparam prom_inst_7.INIT_RAM_00 = 256'h000000001171561557534D54554557534557537534575345D75D555555FD6797;

endmodule //Gowin_pROM
