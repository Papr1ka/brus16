//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.11.03 Education
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Sun Oct 26 16:25:52 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    stack_ssram your_instance_name(
        .dout(dout), //output [31:0] dout
        .wre(wre), //input wre
        .wad(wad), //input [4:0] wad
        .di(di), //input [31:0] di
        .rad(rad), //input [4:0] rad
        .clk(clk) //input clk
    );

//--------Copy end-------------------
