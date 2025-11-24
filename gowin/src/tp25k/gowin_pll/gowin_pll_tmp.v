//Change the instance name and port connections to the signal names
//--------Copy here to design--------
    Gowin_PLL your_instance_name(
        .clkin(clkin), //input  clkin
        .clkout0(clkout0), //output  clkout0
        .lock(lock), //output  lock
        .mdclk(mdclk) //input  mdclk
);


//--------Copy end-------------------
