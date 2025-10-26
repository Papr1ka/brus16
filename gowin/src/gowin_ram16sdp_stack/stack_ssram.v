//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11.03 Education
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Sun Oct 26 16:25:52 2025

module stack_ssram (dout, wre, wad, di, rad, clk);

output [31:0] dout;
input wre;
input [4:0] wad;
input [31:0] di;
input [4:0] rad;
input clk;

wire wad4_inv;
wire lut_f_0;
wire lut_f_1;
wire [3:0] ram16sdp_inst_0_dout;
wire [7:4] ram16sdp_inst_1_dout;
wire [11:8] ram16sdp_inst_2_dout;
wire [15:12] ram16sdp_inst_3_dout;
wire [19:16] ram16sdp_inst_4_dout;
wire [23:20] ram16sdp_inst_5_dout;
wire [27:24] ram16sdp_inst_6_dout;
wire [31:28] ram16sdp_inst_7_dout;
wire [3:0] ram16sdp_inst_8_dout;
wire [7:4] ram16sdp_inst_9_dout;
wire [11:8] ram16sdp_inst_10_dout;
wire [15:12] ram16sdp_inst_11_dout;
wire [19:16] ram16sdp_inst_12_dout;
wire [23:20] ram16sdp_inst_13_dout;
wire [27:24] ram16sdp_inst_14_dout;
wire [31:28] ram16sdp_inst_15_dout;
wire gw_vcc;

assign gw_vcc = 1'b1;

INV inv_inst_0 (.I(wad[4]), .O(wad4_inv));

LUT4 lut_inst_0 (
  .F(lut_f_0),
  .I0(wre),
  .I1(wad4_inv),
  .I2(gw_vcc),
  .I3(gw_vcc)
);
defparam lut_inst_0.INIT = 16'h8000;
LUT4 lut_inst_1 (
  .F(lut_f_1),
  .I0(wre),
  .I1(wad[4]),
  .I2(gw_vcc),
  .I3(gw_vcc)
);
defparam lut_inst_1.INIT = 16'h8000;
RAM16SDP4 ram16sdp_inst_0 (
    .DO(ram16sdp_inst_0_dout[3:0]),
    .DI(di[3:0]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_0),
    .CLK(clk)
);

defparam ram16sdp_inst_0.INIT_0 = 16'h0000;
defparam ram16sdp_inst_0.INIT_1 = 16'h0000;
defparam ram16sdp_inst_0.INIT_2 = 16'h0000;
defparam ram16sdp_inst_0.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_1 (
    .DO(ram16sdp_inst_1_dout[7:4]),
    .DI(di[7:4]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_0),
    .CLK(clk)
);

defparam ram16sdp_inst_1.INIT_0 = 16'h0000;
defparam ram16sdp_inst_1.INIT_1 = 16'h0000;
defparam ram16sdp_inst_1.INIT_2 = 16'h0000;
defparam ram16sdp_inst_1.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_2 (
    .DO(ram16sdp_inst_2_dout[11:8]),
    .DI(di[11:8]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_0),
    .CLK(clk)
);

defparam ram16sdp_inst_2.INIT_0 = 16'h0000;
defparam ram16sdp_inst_2.INIT_1 = 16'h0000;
defparam ram16sdp_inst_2.INIT_2 = 16'h0000;
defparam ram16sdp_inst_2.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_3 (
    .DO(ram16sdp_inst_3_dout[15:12]),
    .DI(di[15:12]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_0),
    .CLK(clk)
);

defparam ram16sdp_inst_3.INIT_0 = 16'h0000;
defparam ram16sdp_inst_3.INIT_1 = 16'h0000;
defparam ram16sdp_inst_3.INIT_2 = 16'h0000;
defparam ram16sdp_inst_3.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_4 (
    .DO(ram16sdp_inst_4_dout[19:16]),
    .DI(di[19:16]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_0),
    .CLK(clk)
);

defparam ram16sdp_inst_4.INIT_0 = 16'h0000;
defparam ram16sdp_inst_4.INIT_1 = 16'h0000;
defparam ram16sdp_inst_4.INIT_2 = 16'h0000;
defparam ram16sdp_inst_4.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_5 (
    .DO(ram16sdp_inst_5_dout[23:20]),
    .DI(di[23:20]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_0),
    .CLK(clk)
);

defparam ram16sdp_inst_5.INIT_0 = 16'h0000;
defparam ram16sdp_inst_5.INIT_1 = 16'h0000;
defparam ram16sdp_inst_5.INIT_2 = 16'h0000;
defparam ram16sdp_inst_5.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_6 (
    .DO(ram16sdp_inst_6_dout[27:24]),
    .DI(di[27:24]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_0),
    .CLK(clk)
);

defparam ram16sdp_inst_6.INIT_0 = 16'h0000;
defparam ram16sdp_inst_6.INIT_1 = 16'h0000;
defparam ram16sdp_inst_6.INIT_2 = 16'h0000;
defparam ram16sdp_inst_6.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_7 (
    .DO(ram16sdp_inst_7_dout[31:28]),
    .DI(di[31:28]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_0),
    .CLK(clk)
);

defparam ram16sdp_inst_7.INIT_0 = 16'h0000;
defparam ram16sdp_inst_7.INIT_1 = 16'h0000;
defparam ram16sdp_inst_7.INIT_2 = 16'h0000;
defparam ram16sdp_inst_7.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_8 (
    .DO(ram16sdp_inst_8_dout[3:0]),
    .DI(di[3:0]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_1),
    .CLK(clk)
);

defparam ram16sdp_inst_8.INIT_0 = 16'h0000;
defparam ram16sdp_inst_8.INIT_1 = 16'h0000;
defparam ram16sdp_inst_8.INIT_2 = 16'h0000;
defparam ram16sdp_inst_8.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_9 (
    .DO(ram16sdp_inst_9_dout[7:4]),
    .DI(di[7:4]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_1),
    .CLK(clk)
);

defparam ram16sdp_inst_9.INIT_0 = 16'h0000;
defparam ram16sdp_inst_9.INIT_1 = 16'h0000;
defparam ram16sdp_inst_9.INIT_2 = 16'h0000;
defparam ram16sdp_inst_9.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_10 (
    .DO(ram16sdp_inst_10_dout[11:8]),
    .DI(di[11:8]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_1),
    .CLK(clk)
);

defparam ram16sdp_inst_10.INIT_0 = 16'h0000;
defparam ram16sdp_inst_10.INIT_1 = 16'h0000;
defparam ram16sdp_inst_10.INIT_2 = 16'h0000;
defparam ram16sdp_inst_10.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_11 (
    .DO(ram16sdp_inst_11_dout[15:12]),
    .DI(di[15:12]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_1),
    .CLK(clk)
);

defparam ram16sdp_inst_11.INIT_0 = 16'h0000;
defparam ram16sdp_inst_11.INIT_1 = 16'h0000;
defparam ram16sdp_inst_11.INIT_2 = 16'h0000;
defparam ram16sdp_inst_11.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_12 (
    .DO(ram16sdp_inst_12_dout[19:16]),
    .DI(di[19:16]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_1),
    .CLK(clk)
);

defparam ram16sdp_inst_12.INIT_0 = 16'h0000;
defparam ram16sdp_inst_12.INIT_1 = 16'h0000;
defparam ram16sdp_inst_12.INIT_2 = 16'h0000;
defparam ram16sdp_inst_12.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_13 (
    .DO(ram16sdp_inst_13_dout[23:20]),
    .DI(di[23:20]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_1),
    .CLK(clk)
);

defparam ram16sdp_inst_13.INIT_0 = 16'h0000;
defparam ram16sdp_inst_13.INIT_1 = 16'h0000;
defparam ram16sdp_inst_13.INIT_2 = 16'h0000;
defparam ram16sdp_inst_13.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_14 (
    .DO(ram16sdp_inst_14_dout[27:24]),
    .DI(di[27:24]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_1),
    .CLK(clk)
);

defparam ram16sdp_inst_14.INIT_0 = 16'h0000;
defparam ram16sdp_inst_14.INIT_1 = 16'h0000;
defparam ram16sdp_inst_14.INIT_2 = 16'h0000;
defparam ram16sdp_inst_14.INIT_3 = 16'h0000;

RAM16SDP4 ram16sdp_inst_15 (
    .DO(ram16sdp_inst_15_dout[31:28]),
    .DI(di[31:28]),
    .WAD(wad[3:0]),
    .RAD(rad[3:0]),
    .WRE(lut_f_1),
    .CLK(clk)
);

defparam ram16sdp_inst_15.INIT_0 = 16'h0000;
defparam ram16sdp_inst_15.INIT_1 = 16'h0000;
defparam ram16sdp_inst_15.INIT_2 = 16'h0000;
defparam ram16sdp_inst_15.INIT_3 = 16'h0000;

MUX2 mux_inst_0 (
  .O(dout[0]),
  .I0(ram16sdp_inst_0_dout[0]),
  .I1(ram16sdp_inst_8_dout[0]),
  .S0(rad[4])
);
MUX2 mux_inst_1 (
  .O(dout[1]),
  .I0(ram16sdp_inst_0_dout[1]),
  .I1(ram16sdp_inst_8_dout[1]),
  .S0(rad[4])
);
MUX2 mux_inst_2 (
  .O(dout[2]),
  .I0(ram16sdp_inst_0_dout[2]),
  .I1(ram16sdp_inst_8_dout[2]),
  .S0(rad[4])
);
MUX2 mux_inst_3 (
  .O(dout[3]),
  .I0(ram16sdp_inst_0_dout[3]),
  .I1(ram16sdp_inst_8_dout[3]),
  .S0(rad[4])
);
MUX2 mux_inst_4 (
  .O(dout[4]),
  .I0(ram16sdp_inst_1_dout[4]),
  .I1(ram16sdp_inst_9_dout[4]),
  .S0(rad[4])
);
MUX2 mux_inst_5 (
  .O(dout[5]),
  .I0(ram16sdp_inst_1_dout[5]),
  .I1(ram16sdp_inst_9_dout[5]),
  .S0(rad[4])
);
MUX2 mux_inst_6 (
  .O(dout[6]),
  .I0(ram16sdp_inst_1_dout[6]),
  .I1(ram16sdp_inst_9_dout[6]),
  .S0(rad[4])
);
MUX2 mux_inst_7 (
  .O(dout[7]),
  .I0(ram16sdp_inst_1_dout[7]),
  .I1(ram16sdp_inst_9_dout[7]),
  .S0(rad[4])
);
MUX2 mux_inst_8 (
  .O(dout[8]),
  .I0(ram16sdp_inst_2_dout[8]),
  .I1(ram16sdp_inst_10_dout[8]),
  .S0(rad[4])
);
MUX2 mux_inst_9 (
  .O(dout[9]),
  .I0(ram16sdp_inst_2_dout[9]),
  .I1(ram16sdp_inst_10_dout[9]),
  .S0(rad[4])
);
MUX2 mux_inst_10 (
  .O(dout[10]),
  .I0(ram16sdp_inst_2_dout[10]),
  .I1(ram16sdp_inst_10_dout[10]),
  .S0(rad[4])
);
MUX2 mux_inst_11 (
  .O(dout[11]),
  .I0(ram16sdp_inst_2_dout[11]),
  .I1(ram16sdp_inst_10_dout[11]),
  .S0(rad[4])
);
MUX2 mux_inst_12 (
  .O(dout[12]),
  .I0(ram16sdp_inst_3_dout[12]),
  .I1(ram16sdp_inst_11_dout[12]),
  .S0(rad[4])
);
MUX2 mux_inst_13 (
  .O(dout[13]),
  .I0(ram16sdp_inst_3_dout[13]),
  .I1(ram16sdp_inst_11_dout[13]),
  .S0(rad[4])
);
MUX2 mux_inst_14 (
  .O(dout[14]),
  .I0(ram16sdp_inst_3_dout[14]),
  .I1(ram16sdp_inst_11_dout[14]),
  .S0(rad[4])
);
MUX2 mux_inst_15 (
  .O(dout[15]),
  .I0(ram16sdp_inst_3_dout[15]),
  .I1(ram16sdp_inst_11_dout[15]),
  .S0(rad[4])
);
MUX2 mux_inst_16 (
  .O(dout[16]),
  .I0(ram16sdp_inst_4_dout[16]),
  .I1(ram16sdp_inst_12_dout[16]),
  .S0(rad[4])
);
MUX2 mux_inst_17 (
  .O(dout[17]),
  .I0(ram16sdp_inst_4_dout[17]),
  .I1(ram16sdp_inst_12_dout[17]),
  .S0(rad[4])
);
MUX2 mux_inst_18 (
  .O(dout[18]),
  .I0(ram16sdp_inst_4_dout[18]),
  .I1(ram16sdp_inst_12_dout[18]),
  .S0(rad[4])
);
MUX2 mux_inst_19 (
  .O(dout[19]),
  .I0(ram16sdp_inst_4_dout[19]),
  .I1(ram16sdp_inst_12_dout[19]),
  .S0(rad[4])
);
MUX2 mux_inst_20 (
  .O(dout[20]),
  .I0(ram16sdp_inst_5_dout[20]),
  .I1(ram16sdp_inst_13_dout[20]),
  .S0(rad[4])
);
MUX2 mux_inst_21 (
  .O(dout[21]),
  .I0(ram16sdp_inst_5_dout[21]),
  .I1(ram16sdp_inst_13_dout[21]),
  .S0(rad[4])
);
MUX2 mux_inst_22 (
  .O(dout[22]),
  .I0(ram16sdp_inst_5_dout[22]),
  .I1(ram16sdp_inst_13_dout[22]),
  .S0(rad[4])
);
MUX2 mux_inst_23 (
  .O(dout[23]),
  .I0(ram16sdp_inst_5_dout[23]),
  .I1(ram16sdp_inst_13_dout[23]),
  .S0(rad[4])
);
MUX2 mux_inst_24 (
  .O(dout[24]),
  .I0(ram16sdp_inst_6_dout[24]),
  .I1(ram16sdp_inst_14_dout[24]),
  .S0(rad[4])
);
MUX2 mux_inst_25 (
  .O(dout[25]),
  .I0(ram16sdp_inst_6_dout[25]),
  .I1(ram16sdp_inst_14_dout[25]),
  .S0(rad[4])
);
MUX2 mux_inst_26 (
  .O(dout[26]),
  .I0(ram16sdp_inst_6_dout[26]),
  .I1(ram16sdp_inst_14_dout[26]),
  .S0(rad[4])
);
MUX2 mux_inst_27 (
  .O(dout[27]),
  .I0(ram16sdp_inst_6_dout[27]),
  .I1(ram16sdp_inst_14_dout[27]),
  .S0(rad[4])
);
MUX2 mux_inst_28 (
  .O(dout[28]),
  .I0(ram16sdp_inst_7_dout[28]),
  .I1(ram16sdp_inst_15_dout[28]),
  .S0(rad[4])
);
MUX2 mux_inst_29 (
  .O(dout[29]),
  .I0(ram16sdp_inst_7_dout[29]),
  .I1(ram16sdp_inst_15_dout[29]),
  .S0(rad[4])
);
MUX2 mux_inst_30 (
  .O(dout[30]),
  .I0(ram16sdp_inst_7_dout[30]),
  .I1(ram16sdp_inst_15_dout[30]),
  .S0(rad[4])
);
MUX2 mux_inst_31 (
  .O(dout[31]),
  .I0(ram16sdp_inst_7_dout[31]),
  .I1(ram16sdp_inst_15_dout[31]),
  .S0(rad[4])
);
endmodule //stack_ssram
