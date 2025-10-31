//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.11.03 Education
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Fri Oct 31 23:17:06 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    collisions_bram_SDPB your_instance_name(
        .dout(dout), //output [63:0] dout
        .clka(clka), //input clka
        .cea(cea), //input cea
        .reseta(reseta), //input reseta
        .clkb(clkb), //input clkb
        .ceb(ceb), //input ceb
        .resetb(resetb), //input resetb
        .oce(oce), //input oce
        .ada(ada), //input [9:0] ada
        .din(din), //input [63:0] din
        .adb(adb) //input [9:0] adb
    );

//--------Copy end-------------------
