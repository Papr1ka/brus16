//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    colors_bram_SDPB your_instance_name(
        .dout(dout), //output [15:0] dout
        .clka(clka), //input clka
        .cea(cea), //input cea
        .reseta(reseta), //input reseta
        .clkb(clkb), //input clkb
        .ceb(ceb), //input ceb
        .resetb(resetb), //input resetb
        .oce(oce), //input oce
        .ada(ada), //input [5:0] ada
        .din(din), //input [15:0] din
        .adb(adb) //input [5:0] adb
    );

//--------Copy end-------------------
