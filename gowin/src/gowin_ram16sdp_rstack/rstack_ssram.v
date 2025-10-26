//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11.03 Education
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Sun Oct 26 16:27:09 2025

module rstack_ssram (dout, di, wad, rad, wre, clk);

output [12:0] dout;
input [12:0] di;
input [3:0] wad;
input [3:0] rad;
input wre;
input clk;

wire gw_gnd;

assign gw_gnd = 1'b0;

RAM16SDP4 ram16sdp_inst_0 (
    .DO(dout[3:0]),
    .DI(di[3:0]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(wre),
    .CLK(clk)
);

defparam ram16sdp_inst_0.INIT_0 = 16'h0000;
defparam ram16sdp_inst_0.INIT_1 = 16'h0000;
defparam ram16sdp_inst_0.INIT_2 = 16'h0000;
defparam ram16sdp_inst_0.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_1 (
    .DO(dout[7:4]),
    .DI(di[7:4]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(wre),
    .CLK(clk)
);

defparam ram16sdp_inst_1.INIT_0 = 16'h0000;
defparam ram16sdp_inst_1.INIT_1 = 16'h0000;
defparam ram16sdp_inst_1.INIT_2 = 16'h0000;
defparam ram16sdp_inst_1.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_2 (
    .DO(dout[11:8]),
    .DI(di[11:8]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(wre),
    .CLK(clk)
);

defparam ram16sdp_inst_2.INIT_0 = 16'h0000;
defparam ram16sdp_inst_2.INIT_1 = 16'h0000;
defparam ram16sdp_inst_2.INIT_2 = 16'h0000;
defparam ram16sdp_inst_2.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_3 (
    .DO(dout[12]),
    .DI(di[12]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(wre),
    .CLK(clk)
);

defparam ram16sdp_inst_3.INIT_0 = 16'h0000;
defparam ram16sdp_inst_3.INIT_1 = 16'h0000;
defparam ram16sdp_inst_3.INIT_2 = 16'h0000;
defparam ram16sdp_inst_3.INIT_3 = 16'h0000;

endmodule //rstack_ssram
