/*
    Brus 16 top module
*/

`include "constants.svh"


module brus16_top #(
    parameter CODE_ADDR_WIDTH = `CODE_ADDR_WIDTH,
    parameter DATA_ADDR_WIDTH = `DATA_ADDR_WIDTH,
    parameter DEFAULT_COLOR = `DEFAULT_COLOR,
    parameter BUTTON_COUNT = `KEY_NUM,
    parameter BUTTON_ADDR = `KEY_MEM
)
(
    input wire clk,
    input wire reset,

    input wire [15:0] buttons_in, // async raw signals from controller

    // explisit output buffer (registers instead of wires)
    output reg hsync_out,
    output reg vsync_out,
    output reg [15:0] rgb_out // colorful rgb 5 6 5 color !
);

/*
    PLL
*/

wire system_clk;

`ifdef SIM

assign system_clk = clk;

`endif

`ifdef GOWIN

wire vga_x5;

Gowin_rPLL rPLL(
    .clkout(vga_x5), //output clkout
    .clkin(clk) //input clkin
);

Gowin_CLKDIV CLKDIV(
    .clkout(system_clk), //output clkout
    .hclkin(vga_x5), //input hclkin
    .resetn(1'b0) //input resetn
);

`endif

`ifdef VIVADO

pll pll (
   // Clock out ports
   .clk_out1(system_clk),
   // Clock in ports
   .clk_in1(clk)
);

`endif

/*
    VGA 640x480
*/

wire display_on;
wire [9:0] hpos;
wire [9:0] vpos;
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

always_ff @(posedge system_clk) begin
    hsync_out <= hsync;
    vsync_out <= vsync;
end

/*
    Main controller
*/

wire copy_start; // signal to start copy
wire copy; // if 1, connect button_controller and rect_copy_controller to data memory
wire resume; // signal to continue cpu work
wire gpu_reset; // signal to reset gpu state to wait for copy

brus16_controller brus16_controller(
    .clk(system_clk),
    .reset(reset),
    .vsync(vsync),
    .copy_start(copy_start),
    .copy(copy),
    .resume(resume),
    .gpu_reset(gpu_reset)
);

/*
    button_controller
*/

wire bc_mem_dout_we;
wire [DATA_ADDR_WIDTH-1:0] bc_mem_dout_addr;
wire [15:0] bc_mem_dout;

button_controller #(
    .BUTTON_COUNT(BUTTON_COUNT),
    .BUTTON_ADDR(BUTTON_ADDR)
)
button_controller(
    .clk(system_clk),
    .reset(resume),
    .copy_start(copy_start),
    .buttons_in(buttons_in),

    .mem_dout_we(bc_mem_dout_we),
    .mem_dout_addr(bc_mem_dout_addr),
    .mem_dout(bc_mem_dout)
);

/*
    cpu
*/

wire [CODE_ADDR_WIDTH-1:0] program_memory_addr_bus;
wire [15:0] program_memory_data_bus;
wire data_memory_write_we_bus;
wire [DATA_ADDR_WIDTH-1:0] data_memory_write_addr_bus;
wire [15:0] data_memory_write_data_bus;
wire [DATA_ADDR_WIDTH-1:0] data_memory_read_addr_bus;
wire [15:0] data_memory_read_data_bus;

wire cpu_mem_dout_we;
wire [DATA_ADDR_WIDTH-1:0] cpu_mem_dout_addr;
wire [15:0] cpu_mem_dout;
wire [DATA_ADDR_WIDTH-1:0] cpu_mem_din_addr;

wire [DATA_ADDR_WIDTH-1:0] rc_controller_mem_din_addr;

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

/*
    data memory
*/

assign data_memory_read_addr_bus = copy ? rc_controller_mem_din_addr : cpu_mem_din_addr;
assign data_memory_write_we_bus = copy ? bc_mem_dout_we : cpu_mem_dout_we;
assign data_memory_write_addr_bus = copy ? bc_mem_dout_addr : cpu_mem_dout_addr;
assign data_memory_write_data_bus = copy ? bc_mem_dout : cpu_mem_dout;

bsram #(
    .LOAD_PROGRAM(0)
)
memory(
    .clk(system_clk),
    .mem_dout_addr(data_memory_read_addr_bus),
    .mem_dout(data_memory_read_data_bus),

    .we(data_memory_write_we_bus),
    .mem_din_addr(data_memory_write_addr_bus),
    .mem_din(data_memory_write_data_bus)
);

/*
    program memory
*/

/* verilator lint_off PINMISSING */
bsram program_memory(
    .clk(system_clk),
    .mem_dout_addr(program_memory_addr_bus),
    .mem_dout(program_memory_data_bus)
);
/* verilator lint_on PINMISSING */

/*
    rect copy controller
*/
wire [15:0] gpu_data;

rect_copy_controller rect_copy_controller(
    .clk(system_clk),
    .reset(!vsync),
    .copy_start(copy_start),
    
    .mem_din_addr(rc_controller_mem_din_addr),
    .mem_din(data_memory_read_data_bus),

    .mem_dout(gpu_data)
);

/*
    gpu
*/

wire [15:0] pixel_color; // rgb 5 6 5
wire [15:0] rgb = display_on ? pixel_color : DEFAULT_COLOR;

gpu gpu(
    .clk(system_clk),
    .copy_start(copy_start),
    .reset(gpu_reset),
    
    .x_coord({6'b0, hpos}),
    .y_coord({6'b0, vpos}),
    .mem_din(gpu_data),
    .color(pixel_color)
);

always_ff @(posedge system_clk) begin
    rgb_out <= rgb;
end

initial begin
    hsync_out = 1'b0;
    vsync_out = 1'b0;
    rgb_out = 16'b0;
end

endmodule
