//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_rPLL your_instance_name(
        .clkout(clkout), //output clkout
        .lock(lock), //output lock
        .clkin(clkin) //input clkin
    );

//--------Copy end-------------------
