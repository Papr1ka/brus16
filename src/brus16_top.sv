/*
    Brus 16 top module
*/

`include "constants.svh"


module brus16_top #(
    parameter CODE_ADDR_WIDTH     = `CODE_ADDR_WIDTH,
    parameter DATA_ADDR_WIDTH     = `DATA_ADDR_WIDTH,
    parameter DEFAULT_COLOR       = `DEFAULT_COLOR,
    parameter BUTTON_COUNT        = `KEY_NUM,
    parameter BUTTON_ADDR         = `KEY_MEM,
    parameter COORD_WIDTH         = `COORD_WIDTH,
    parameter RESET_COUNTER_WIDTH = `RESET_COUNTER_WIDTH,
    parameter DS2_CLK_RATIO       = `DS2_CLK_RATIO
)
(
    input wire clk,

// DUALSHOCK 2 controllers
/* ONLY WHEN CONTROLLERS ARE ENABLED */
`ifndef DISABLE_CONTROLLERS
    output     joystick_clk_0,
    output     joystick_mosi_0,
    input      joystick_miso_0,
    output reg joystick_cs_0,
    
    output     joystick_clk_1,
    output     joystick_mosi_1,
    input      joystick_miso_1,
    output reg joystick_cs_1,
`endif
/* END */

/* SIMULATION ONLY */
`ifdef SIM
    output wire hsync_out,
    output wire vsync_out,
    output wire [15:0] rgb_out,
    input  wire [15:0] buttons_in,
`endif
/* END */

    output wire [3:0] hdmi_tx_n,
    output wire [3:0] hdmi_tx_p
);

reg [4:0][2:0]   dvh_delay;  // shift register (delay)
reg [2:0]        dvh;        // vsync, display_on_reg, hsync
reg [15:0]       rgb_reg;

/* SIMULATION ONLY */
`ifdef SIM
assign hsync_out = dvh_delay[4][0];
assign vsync_out = dvh_delay[4][1];
assign rgb_out = rgb_reg;
`endif
/* END */


/* ----------------------------------- PLL ---------------------------------- */

wire system_clk; // clk for the whole system, 25.2 MHz
wire vga_x5;     // system_clk x5 (126 MHz) (for HDMI)
wire lock;       // PLL lock

/* SIMULATION ONLY */
`ifdef SIM
assign system_clk = clk;
assign vga_x5 = 1'b0;
assign lock = 1'b1;
`endif
/* END */


/* FOR GOWIN ONLY */
`ifdef GOWIN

`ifdef TN20K
Gowin_rPLL rPLL(
    .clkout(vga_x5), // output clkout
    .lock(lock),     // output lock
    .clkin(clk)      // input clkin
);
`endif

`ifdef TP25k
Gowin_PLL rPLL(
   .clkout0(vga_x5), // output clkout
   .lock(lock),      // output lock
   .clkin(clk),      // input clkin
   .mdclk(clk)       // input mdclk
);
`endif

Gowin_CLKDIV clkDIV(
    .clkout(system_clk), // output clkout
    .hclkin(vga_x5),     // input hclkin
    .resetn(lock),       // input resetn
    .calib(1'b1)         // input calib
);

`endif
/* END */


/* FOR VIVADO ONLY */
`ifdef VIVADO

PLL pll(
    .clk_in1(clk),
    .clk_out1(vga_x5),
    .clk_out2(system_clk),
    .locked(lock)
);

`endif
/* END */

/* ------------------------------ Global reset ------------------------------ */

reg [RESET_COUNTER_WIDTH-1:0] reset_counter = RESET_COUNTER_WIDTH'(0);
reg was_reset = 1'b0;

wire reset;

always_ff @(posedge system_clk) begin
    reset_counter <= reset_counter + 1;
    if (reset_counter == {RESET_COUNTER_WIDTH{1'b1}}) begin
        was_reset <= 1'b1;
    end else begin
        was_reset <= was_reset;
    end
end


/* ------------------------------- VGA 640x480 ------------------------------ */

wire [9:0] hpos;
wire [9:0] vpos;
wire display_on;
wire hsync;
wire vsync;

vga_controller vga_controller(
    .clk(system_clk),
    .reset(reset),

    .hsync(hsync),
    .vsync(vsync),

    .display_on(display_on),
    .hpos(hpos),
    .vpos(vpos)
);


/* ----------------------------- Main controller ---------------------------- */
wire copy_start;    // Signal to start copy
wire copy;          // If 1, connect button_controller and rect_copy_controller to data memory
wire resume;        // Signal to continue cpu work
wire gpu_reset;     // Signal to reset gpu state to wait for copy

brus16_controller brus16_controller(
    .clk(system_clk),
    .reset(reset),
    .vpos(vpos),
    .copy_start(copy_start),
    .copy(copy),
    .resume(resume),
    .gpu_reset(gpu_reset)
);

/* -------------------------- dualshok2_controllers ------------------------- */

/* ONLY WHEN CONTROLLERS ARE ENABLED */
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
    .clk(system_clk),
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
    .clk(system_clk),
    .reset(reset),
    
    .spi_miso(joystick_miso_1),
    .spi_clk(joystick_clk_1),
    .spi_cs(joystick_cs_1),
    .spi_mosi(joystick_mosi_1),

    .data_valid(data_valid_1),
    .rx_buffer(joystick_buttons_1)
);

assign reset = ~lock | ~was_reset | (~joystick_buttons_0[12] && data_valid_0) | (~joystick_buttons_1[12] && data_valid_1);

`endif
/* END */

/* ONLY WHEN CONTROLLERS ARE DISABLED */
`ifdef DISABLE_CONTROLLERS
assign reset = ~lock | ~was_reset;
wire [15:0] brus_buttons = 16'b0;
`endif
/* END */


/* ---------------------------- button_controller --------------------------- */

wire                       bc_mem_dout_we;
wire [DATA_ADDR_WIDTH-1:0] bc_mem_dout_addr;
wire [15:0]                bc_mem_dout;

/* ONLY WHEN BUTTONS ARE DISABLED */
`ifdef DISABLE_CONTROLLERS
assign bc_mem_dout_we   = 1'b0;
assign bc_mem_dout_addr = DATA_ADDR_WIDTH'(0);
assign bc_mem_dout      = 16'b0;
`endif
/* END */

/* ONLY WHEN BUTTONS ARE ENABLED*/
`ifndef DISABLE_BUTTONS
button_controller #(
    .BUTTON_COUNT(BUTTON_COUNT),
    .BUTTON_ADDR(BUTTON_ADDR)
)
button_controller(
    .clk(system_clk),
    .reset(reset | resume),
    .copy_start(copy_start),

`ifdef SIM
    .buttons_in(buttons_in),
`endif
`ifndef SIM
    .buttons_in(brus_buttons),
`endif

    .mem_dout_we(bc_mem_dout_we),
    .mem_dout_addr(bc_mem_dout_addr),
    .mem_dout(bc_mem_dout)
);
`endif
/* END */


/* ------------------------------ memory buses ------------------------------ */

/* Program memory buses */
wire [CODE_ADDR_WIDTH-1:0] program_memory_addr_bus;
wire [15:0]                program_memory_data_bus;

/* Data memory read buses */
wire [DATA_ADDR_WIDTH-1:0] data_memory_read_addr_bus;
wire [15:0]                data_memory_read_data_bus;

/* Data memory write buses */
wire                       data_memory_write_we_bus;
wire [DATA_ADDR_WIDTH-1:0] data_memory_write_addr_bus;
wire [15:0]                data_memory_write_data_bus;


/* ----------------------------------- cpu ---------------------------------- */

/* cpu output buses for memory */
wire                       cpu_mem_dout_we;
wire [DATA_ADDR_WIDTH-1:0] cpu_mem_dout_addr;
wire [15:0]                cpu_mem_dout;
wire [DATA_ADDR_WIDTH-1:0] cpu_mem_din_addr;

cpu cpu(
    .clk(system_clk),
    .resume(resume),
    .reset(reset),
    .code_addr(program_memory_addr_bus),
    .instruction(program_memory_data_bus),
    .mem_din_addr(cpu_mem_din_addr),
    .mem_din(data_memory_read_data_bus),
    .mem_dout_we(cpu_mem_dout_we),
    .mem_dout_addr(cpu_mem_dout_addr),
    .mem_dout(cpu_mem_dout)
);


/* -------------------------- rect copy controller -------------------------- */

wire [DATA_ADDR_WIDTH-1:0] rc_controller_mem_din_addr;
wire [15:0]                gpu_data; // gpu rect copy bus

wire  [2:0]  state;
wire  [9:0]  wait_counter;
wire  [3:0]  rect_counter;
wire  [1:0]  batch_counter;
wire         batch_completed;

rect_copy_controller copy_controller(
    .clk(system_clk),
    .reset(!copy),
    .copy_start(copy_start),

    .mem_din_addr(rc_controller_mem_din_addr), // data mem, read address
    .mem_din(data_memory_read_data_bus),       // data mem, read data

    .mem_dout(gpu_data),                       // data mem, write data
    .state_out(state),
    .wait_counter_out(wait_counter),
    .rect_counter_out(rect_counter),
    .batch_counter_out(batch_counter),
    .batch_completed_out(batch_completed)
);


/* ------------------------------- data memory ------------------------------ */

assign data_memory_read_addr_bus  = copy ? rc_controller_mem_din_addr : cpu_mem_din_addr;
assign data_memory_write_we_bus   = copy ? bc_mem_dout_we             : cpu_mem_dout_we;
assign data_memory_write_addr_bus = copy ? bc_mem_dout_addr           : cpu_mem_dout_addr;
assign data_memory_write_data_bus = copy ? bc_mem_dout                : cpu_mem_dout;

bsram memory(
    .clk(system_clk),
    .mem_dout_addr(data_memory_read_addr_bus),
    .mem_dout(data_memory_read_data_bus),

    .we(data_memory_write_we_bus),
    .mem_din_addr(data_memory_write_addr_bus),
    .mem_din(data_memory_write_data_bus)
);


/* ----------------------------- program memory ----------------------------- */

prom program_memory(
    .clk(system_clk),
    .mem_dout_addr(program_memory_addr_bus),
    .mem_dout(program_memory_data_bus)
);


/* ----------------------------------- gpu ---------------------------------- */

wire [15:0] pixel_color; // rgb 5 6 5
wire [15:0] rgb = dvh_delay[4][2] ? pixel_color : DEFAULT_COLOR;

/* ONLY IF GPU IS DISABLED */
`ifdef DISABLE_GPU
assign pixel_color = 16'b1111100000000000;
`endif
/* END */

/* ONLY IF GPU IS ENABLED */
`ifndef DISABLE_GPU
gpu gpu(
    .clk(system_clk),
    .copy_start(copy_start),
    .reset(gpu_reset),

    .mem_din(gpu_data),
    .fsm_state(state),
    .coord_generator(wait_counter),
    .rect_counter(rect_counter),
    .batch_counter(batch_counter),
    .batch_completed(batch_completed),
    .x_coord(hpos),
    .y_coord(vpos),
    .color(pixel_color)
);
`endif
/* END */


/* ---------------------------------- HDMI ---------------------------------- */

// rgb 5 6 5 decode
wire [23:0] rgb_8_8_8 = {
    rgb_reg[15:11], rgb_reg[15:13],
    rgb_reg[10:5], rgb_reg[10:9],
    rgb_reg[4:0], rgb_reg[4:2]
};

/* ONLY FOR GOWIN */
`ifdef GOWIN
hdmi hdmi(
    .reset(~lock),
    .hdmi_clk(system_clk),
    .hdmi_clk_5x(vga_x5),
    .hve(dvh_delay[4]),
    .rgb(rgb_8_8_8),
    .hdmi_tx_n(hdmi_tx_n),
    .hdmi_tx_p(hdmi_tx_p)
);
`endif
/* END */

/* SIMULATION + VIVADO ONLY */
`ifndef GOWIN
assign hdmi_tx_n = 4'b0;
assign hdmi_tx_p = 4'b0;
`endif
/* END */


/* ----------------------------- SEQUENTIAL LOGIC ----------------------------- */

always_ff @(posedge system_clk) begin
    if (reset) begin
        rgb_reg            <= 16'b0;
        dvh                <= 3'b0;
        dvh_delay          <= '0;
    end else begin
        rgb_reg            <= rgb;
        dvh                <= {display_on, vsync, hsync};
        dvh_delay          <= {dvh_delay[3:0], dvh};
    end
end

endmodule
