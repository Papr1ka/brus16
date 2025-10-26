//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.11.03 Education
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Sun Oct 26 16:27:09 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    rstack_ssram your_instance_name(
        .dout(dout), //output [12:0] dout
        .di(di), //input [12:0] di
        .wad(wad), //input [3:0] wad
        .rad(rad), //input [3:0] rad
        .wre(wre), //input wre
        .clk(clk) //input clk
    );

//--------Copy end-------------------
