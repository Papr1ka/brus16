`include "constants.svh"

module buttons_top
#(
    parameter DATA_ADDR_WIDTH = `DATA_ADDR_WIDTH,
    parameter DS2_CLK_RATIO   = `DS2_CLK_RATIO,
    parameter BUTTON_COUNT    = `KEY_NUM,
    parameter BUTTON_ADDR     = `KEY_MEM
)
(
    input wire clk,
    input wire reset,
    input wire copy_start,
    input wire bc_reset_pulse,

`ifndef DISABLE_CONTROLLERS
    output wire joystick_clk_0,
    output wire joystick_mosi_0,
    input  wire joystick_miso_0,
    output wire joystick_cs_0,
    
    output wire joystick_clk_1,
    output wire joystick_mosi_1,
    input  wire joystick_miso_1,
    output wire joystick_cs_1,
`endif

    output wire                       mem_dout_we,
    output wire [DATA_ADDR_WIDTH-1:0] mem_dout_addr,
    output wire [15:0]                mem_dout
);

`ifndef DISABLE_CONTROLLERS
wire [15:0] joystick_buttons_0;
wire [15:0] joystick_buttons_1;
wire        data_valid_0;
wire        data_valid_1;

/*
    CHEATSHEET
    brus_buttons[0] -> KEY_MEM
    brus_buttons[1] -> KEY_MEM + 1
    brus_buttons[15] -> KEY_MEM + 15

    joystick_buttons[0]:  square
    joystick_buttons[1]:  cross
    joystick_buttons[2]:  circle
    joystick_buttons[3]:  triangle
    joystick_buttons[4]:  R1
    joystick_buttons[5]:  L1
    joystick_buttons[6]:  R2
    joystick_buttons[7]:  L2
    joystick_buttons[8]:  L
    joystick_buttons[9]:  D
    joystick_buttons[10]: R
    joystick_buttons[11]: U
    joystick_buttons[12]: start
    joystick_buttons[13]: R3
    joystick_buttons[14]: L3
    joystick_buttons[15]: select
*/

wire [15:0] brus_buttons = ~{
    // player 2
    joystick_buttons_1[2],  // circle
    joystick_buttons_1[3],  // triangle
    joystick_buttons_1[1],  // cross
    joystick_buttons_1[0],  // square
    joystick_buttons_1[10], // R
    joystick_buttons_1[8],  // L
    joystick_buttons_1[9],  // D
    joystick_buttons_1[11], // U

    // player 1
    joystick_buttons_0[2],  // circle
    joystick_buttons_0[3],  // triangle
    joystick_buttons_0[1],  // cross
    joystick_buttons_0[0],  // square
    joystick_buttons_0[10], // R
    joystick_buttons_0[8],  // L
    joystick_buttons_0[9],  // D
    joystick_buttons_0[11]  // U
};

dualshock_spi_master #(
    .CLK_RATIO(DS2_CLK_RATIO)
)
controller0 (
    .clk(clk),
    .reset(reset),
    
    .spi_miso(joystick_miso_0),
    .spi_clk(joystick_clk_0),
    .spi_cs(joystick_cs_0),
    .spi_mosi(joystick_mosi_0),

    .data_valid(data_valid_0),
    .rx_buffer(joystick_buttons_0)
);

dualshock_spi_master #(
    .CLK_RATIO(DS2_CLK_RATIO)
)
controller1 (
    .clk(clk),
    .reset(reset),
    
    .spi_miso(joystick_miso_1),
    .spi_clk(joystick_clk_1),
    .spi_cs(joystick_cs_1),
    .spi_mosi(joystick_mosi_1),

    .data_valid(data_valid_1),
    .rx_buffer(joystick_buttons_1)
);


button_controller #(
    .BUTTON_COUNT(BUTTON_COUNT),
    .BUTTON_ADDR(BUTTON_ADDR)
)
button_controller(
    .clk(clk),
    .reset(reset | bc_reset_pulse),
    .copy_start(copy_start),

`ifdef SIM
    .buttons_in(buttons_in),
`endif
`ifndef SIM
    .buttons_in(brus_buttons),
`endif

    .mem_dout_we(mem_dout_we),
    .mem_dout_addr(mem_dout_addr),
    .mem_dout(mem_dout)
);
`endif



`ifdef DISABLE_CONTROLLERS
wire [15:0] brus_buttons     = 16'b0;

assign      mem_dout_we   = 1'b0;
assign      mem_dout_addr = DATA_ADDR_WIDTH'(0);
assign      mem_dout      = 16'b0;
`endif

endmodule
