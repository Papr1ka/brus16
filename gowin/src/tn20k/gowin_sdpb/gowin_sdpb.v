module Gowin_SDPB (dout, clka, cea, reseta, clkb, ceb, resetb, oce, ada, din, adb);

output [15:0] dout;
input clka;
input cea;
input reseta;
input clkb;
input ceb;
input resetb;
input oce;
input [12:0] ada;
input [15:0] din;
input [12:0] adb;

wire [29:0] sdpb_inst_0_dout_w;
wire [29:0] sdpb_inst_1_dout_w;
wire [29:0] sdpb_inst_2_dout_w;
wire [29:0] sdpb_inst_3_dout_w;
wire [29:0] sdpb_inst_4_dout_w;
wire [29:0] sdpb_inst_5_dout_w;
wire [29:0] sdpb_inst_6_dout_w;
wire [29:0] sdpb_inst_7_dout_w;
wire gw_gnd;

assign gw_gnd = 1'b0;

SDPB sdpb_inst_0 (
    .DO({sdpb_inst_0_dout_w[29:0],dout[1:0]}),
    .CLKA(clka),
    .CEA(cea),
    .RESETA(reseta),
    .CLKB(clkb),
    .CEB(ceb),
    .RESETB(resetb),
    .OCE(oce),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[12:0],gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[1:0]}),
    .ADB({adb[12:0],gw_gnd})
);

defparam sdpb_inst_0.READ_MODE = 1'b0;
defparam sdpb_inst_0.BIT_WIDTH_0 = 2;
defparam sdpb_inst_0.BIT_WIDTH_1 = 2;
defparam sdpb_inst_0.BLK_SEL_0 = 3'b000;
defparam sdpb_inst_0.BLK_SEL_1 = 3'b000;
defparam sdpb_inst_0.RESET_MODE = "SYNC";
defparam sdpb_inst_0.INIT_RAM_00 = 256'hC22C3883C03F00FC014A813843B40BC0BC3C03F00FC014A815001007507004E4;
defparam sdpb_inst_0.INIT_RAM_01 = 256'h14A810F03040C03443C03F00FC014A812F82F421421C3C03F00FC014A812C02C;
defparam sdpb_inst_0.INIT_RAM_02 = 256'h8E60EC1E64EC0EC18429067C07F04FC014A81802913C03C00380383C03F00FC0;
defparam sdpb_inst_0.INIT_RAM_03 = 256'h64E64EC1E80E64EC1E64EA4EC1EA0EA4EC1CA0C44EC1EA0EA0EC1EA4EA0EC1C4;
defparam sdpb_inst_0.INIT_RAM_04 = 256'h0000000000000000000000000000000000000000000000000000A4EA0E64EC1E;

SDPB sdpb_inst_1 (
    .DO({sdpb_inst_1_dout_w[29:0],dout[3:2]}),
    .CLKA(clka),
    .CEA(cea),
    .RESETA(reseta),
    .CLKB(clkb),
    .CEB(ceb),
    .RESETB(resetb),
    .OCE(oce),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[12:0],gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[3:2]}),
    .ADB({adb[12:0],gw_gnd})
);

defparam sdpb_inst_1.READ_MODE = 1'b0;
defparam sdpb_inst_1.BIT_WIDTH_0 = 2;
defparam sdpb_inst_1.BIT_WIDTH_1 = 2;
defparam sdpb_inst_1.BLK_SEL_0 = 3'b000;
defparam sdpb_inst_1.BLK_SEL_1 = 3'b000;
defparam sdpb_inst_1.RESET_MODE = "SYNC";
defparam sdpb_inst_1.INIT_RAM_00 = 256'h01801E81A43942943D45401A43942942941A43942943D4540310340350200000;
defparam sdpb_inst_1.INIT_RAM_01 = 256'hD45402240403301AC1A43942943D45400240201B038C1A43942943D454000800;
defparam sdpb_inst_1.INIT_RAM_02 = 256'h8850FC0854FC0BC0110401DA4F94E943D4540C06B73CC3CC3DC3C81A43942943;
defparam sdpb_inst_1.INIT_RAM_03 = 256'h44954FC08B0954FC0944994FC0980994FC0B80B44FC0980990FC0984990FC0A4;
defparam sdpb_inst_1.INIT_RAM_04 = 256'h0000000000000000000000000000000000000000000000000000F0980954FC09;

SDPB sdpb_inst_2 (
    .DO({sdpb_inst_2_dout_w[29:0],dout[5:4]}),
    .CLKA(clka),
    .CEA(cea),
    .RESETA(reseta),
    .CLKB(clkb),
    .CEB(ceb),
    .RESETB(resetb),
    .OCE(oce),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[12:0],gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[5:4]}),
    .ADB({adb[12:0],gw_gnd})
);

defparam sdpb_inst_2.READ_MODE = 1'b0;
defparam sdpb_inst_2.BIT_WIDTH_0 = 2;
defparam sdpb_inst_2.BIT_WIDTH_1 = 2;
defparam sdpb_inst_2.BLK_SEL_0 = 3'b000;
defparam sdpb_inst_2.BLK_SEL_1 = 3'b000;
defparam sdpb_inst_2.RESET_MODE = "SYNC";
defparam sdpb_inst_2.INIT_RAM_00 = 256'h48348302580483407C0400A1C80CB00B002580483407C04000700A0300280000;
defparam sdpb_inst_2.INIT_RAM_01 = 256'hC040082C83C82C8382580483407C04008248248248302580483407C040083483;
defparam sdpb_inst_2.INIT_RAM_02 = 256'h0900D00900D00900003401E58C48F407C0400407558388388208302580483407;
defparam sdpb_inst_2.INIT_RAM_03 = 256'h10800D00900800D00810800D00810800D00810800D00810800D00810800D0090;
defparam sdpb_inst_2.INIT_RAM_04 = 256'h000000000000000000000000000000000000000000000000000050810800D008;

SDPB sdpb_inst_3 (
    .DO({sdpb_inst_3_dout_w[29:0],dout[7:6]}),
    .CLKA(clka),
    .CEA(cea),
    .RESETA(reseta),
    .CLKB(clkb),
    .CEB(ceb),
    .RESETB(resetb),
    .OCE(oce),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[12:0],gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[7:6]}),
    .ADB({adb[12:0],gw_gnd})
);

defparam sdpb_inst_3.READ_MODE = 1'b0;
defparam sdpb_inst_3.BIT_WIDTH_0 = 2;
defparam sdpb_inst_3.BIT_WIDTH_1 = 2;
defparam sdpb_inst_3.BLK_SEL_0 = 3'b000;
defparam sdpb_inst_3.BLK_SEL_1 = 3'b000;
defparam sdpb_inst_3.RESET_MODE = "SYNC";
defparam sdpb_inst_3.INIT_RAM_00 = 256'h00000000000000004009400000000000000000000004009402602603000E0000;
defparam sdpb_inst_3.INIT_RAM_01 = 256'h0094000000000000000000000040094000000000000000000000040094000000;
defparam sdpb_inst_3.INIT_RAM_02 = 256'h0000C00000C0000000F832C00C00C00400940003840000000000000000000004;
defparam sdpb_inst_3.INIT_RAM_03 = 256'h00000C00000000C00000000C00000000C00000000C00000000C00000000C0000;
defparam sdpb_inst_3.INIT_RAM_04 = 256'h000000000000000000000000000000000000000000000000000000000000C000;

SDPB sdpb_inst_4 (
    .DO({sdpb_inst_4_dout_w[29:0],dout[9:8]}),
    .CLKA(clka),
    .CEA(cea),
    .RESETA(reseta),
    .CLKB(clkb),
    .CEB(ceb),
    .RESETB(resetb),
    .OCE(oce),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[12:0],gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[9:8]}),
    .ADB({adb[12:0],gw_gnd})
);

defparam sdpb_inst_4.READ_MODE = 1'b0;
defparam sdpb_inst_4.BIT_WIDTH_0 = 2;
defparam sdpb_inst_4.BIT_WIDTH_1 = 2;
defparam sdpb_inst_4.BLK_SEL_0 = 3'b000;
defparam sdpb_inst_4.BLK_SEL_1 = 3'b000;
defparam sdpb_inst_4.RESET_MODE = "SYNC";
defparam sdpb_inst_4.INIT_RAM_00 = 256'h0000000800800800400800000000000000800800800400800100100300160000;
defparam sdpb_inst_4.INIT_RAM_01 = 256'h0080000000000000080080080040080000000000000080080080040080000000;
defparam sdpb_inst_4.INIT_RAM_02 = 256'h0400C00400C00400002000C00C00C00400800001550000000000008008008004;
defparam sdpb_inst_4.INIT_RAM_03 = 256'h00400C00400400C00400400C00400400C00400400C00400400C00400400C0040;
defparam sdpb_inst_4.INIT_RAM_04 = 256'h000000000000000000000000000000000000000000000000000000400400C004;

SDPB sdpb_inst_5 (
    .DO({sdpb_inst_5_dout_w[29:0],dout[11:10]}),
    .CLKA(clka),
    .CEA(cea),
    .RESETA(reseta),
    .CLKB(clkb),
    .CEB(ceb),
    .RESETB(resetb),
    .OCE(oce),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[12:0],gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[11:10]}),
    .ADB({adb[12:0],gw_gnd})
);

defparam sdpb_inst_5.READ_MODE = 1'b0;
defparam sdpb_inst_5.BIT_WIDTH_0 = 2;
defparam sdpb_inst_5.BIT_WIDTH_1 = 2;
defparam sdpb_inst_5.BLK_SEL_0 = 3'b000;
defparam sdpb_inst_5.BLK_SEL_1 = 3'b000;
defparam sdpb_inst_5.RESET_MODE = "SYNC";
defparam sdpb_inst_5.INIT_RAM_00 = 256'h0400400C00C00C00000800400400400400C00C00C00000800000000300200000;
defparam sdpb_inst_5.INIT_RAM_01 = 256'h00800400400400400C00C00C00000800400400400400C00C00C0000080040040;
defparam sdpb_inst_5.INIT_RAM_02 = 256'h0800C00800C0080000000000000000000080000500400400400400C00C00C000;
defparam sdpb_inst_5.INIT_RAM_03 = 256'h00800C00800800C00800800C00800800C00800800C00800800C00800800C0080;
defparam sdpb_inst_5.INIT_RAM_04 = 256'h000000000000000000000000000000000000000000000000000000800800C008;

SDPB sdpb_inst_6 (
    .DO({sdpb_inst_6_dout_w[29:0],dout[13:12]}),
    .CLKA(clka),
    .CEA(cea),
    .RESETA(reseta),
    .CLKB(clkb),
    .CEB(ceb),
    .RESETB(resetb),
    .OCE(oce),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[12:0],gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[13:12]}),
    .ADB({adb[12:0],gw_gnd})
);

defparam sdpb_inst_6.READ_MODE = 1'b0;
defparam sdpb_inst_6.BIT_WIDTH_0 = 2;
defparam sdpb_inst_6.BIT_WIDTH_1 = 2;
defparam sdpb_inst_6.BLK_SEL_0 = 3'b000;
defparam sdpb_inst_6.BLK_SEL_1 = 3'b000;
defparam sdpb_inst_6.RESET_MODE = "SYNC";
defparam sdpb_inst_6.INIT_RAM_00 = 256'h0C00C00C00C00C00000C00C00C00C00C00C00C00C00000C00200200300100000;
defparam sdpb_inst_6.INIT_RAM_01 = 256'h00C00C00C00C00C00C00C00C00000C00C00C00C00C00C00C00C00000C00C00C0;
defparam sdpb_inst_6.INIT_RAM_02 = 256'h0400C00400C00400001000C00C00C00000C0000300C00C00C00C00C00C00C000;
defparam sdpb_inst_6.INIT_RAM_03 = 256'h00400C00400400C00400400C00400400C00400400C00400400C00400400C0040;
defparam sdpb_inst_6.INIT_RAM_04 = 256'h000000000000000000000000000000000000000000000000000000400400C004;

SDPB sdpb_inst_7 (
    .DO({sdpb_inst_7_dout_w[29:0],dout[15:14]}),
    .CLKA(clka),
    .CEA(cea),
    .RESETA(reseta),
    .CLKB(clkb),
    .CEB(ceb),
    .RESETB(resetb),
    .OCE(oce),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[12:0],gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[15:14]}),
    .ADB({adb[12:0],gw_gnd})
);

defparam sdpb_inst_7.READ_MODE = 1'b0;
defparam sdpb_inst_7.BIT_WIDTH_0 = 2;
defparam sdpb_inst_7.BIT_WIDTH_1 = 2;
defparam sdpb_inst_7.BLK_SEL_0 = 3'b000;
defparam sdpb_inst_7.BLK_SEL_1 = 3'b000;
defparam sdpb_inst_7.RESET_MODE = "SYNC";
defparam sdpb_inst_7.INIT_RAM_00 = 256'h0800800C00C00C00000000800800800800C00C00C00000000000000300000000;
defparam sdpb_inst_7.INIT_RAM_01 = 256'h00000800800800800C00C00C00000000800800800800C00C00C0000000080080;
defparam sdpb_inst_7.INIT_RAM_02 = 256'h0000C00000C0000000100040040040000000000000800800800800C00C00C000;
defparam sdpb_inst_7.INIT_RAM_03 = 256'h00000C00000000C00000000C00000000C00000000C00000000C00000000C0000;
defparam sdpb_inst_7.INIT_RAM_04 = 256'h000000000000000000000000000000000000000000000000000000000000C000;

endmodule //Gowin_SDPB
