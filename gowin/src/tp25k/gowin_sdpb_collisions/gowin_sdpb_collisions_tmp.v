//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    collisions_bram_SDPB your_instance_name(
        .dout(dout), //output [63:0] dout
        .clka(clka), //input clka
        .cea(cea), //input cea
        .clkb(clkb), //input clkb
        .ceb(ceb), //input ceb
        .oce(oce), //input oce
        .reset(reset), //input reset
        .ada(ada), //input [9:0] ada
        .din(din), //input [63:0] din
        .adb(adb) //input [9:0] adb
    );

//--------Copy end-------------------
