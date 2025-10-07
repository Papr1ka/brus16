/*
    Brus 16 top module
*/

module brus16_top(
    input wire clk,
    input wire reset,

    output wire hsync,
    output wire vsync,
    input wire [7:0] switches_p1, // button inputs from 8bitworkshop IDE
    input wire [7:0] switches_p2, 
    output wire [2:0] rgb // for 8bitworkshop IDE (We have rgb 565 color)
);

parameter CODE_WIDTH = 13;
parameter DATA_WIDTH = 13;
parameter DEFAULT_COLOR = 3'b0;

/*
    VGA (CRT for 8-bitworkshop IDE)
*/

wire display_on;
wire [9:0] hpos;
wire [9:0] vpos;

vga_controller vga_controller(
    .clk(clk),
    .reset(reset),

    .hsync(hsync),
    .vsync(vsync),

    .display_on(display_on),
    .hpos(hpos),
    .vpos(vpos)
);

/*
    Main controller
*/

wire copy_start; // signal to start copy
wire copy; // if 1, connect button_controller and rect_copy_controller to data memory
wire resume; // signal to continue cpu work
wire gpu_reset; // signal to reset gpu state to wait for copy

brus16_controller brus16_controller(
    .clk(clk),
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
wire [DATA_WIDTH-1:0] bc_mem_dout_addr;
wire [15:0] bc_mem_dout;

button_controller #(
    .BUTTON_COUNT(12),
    .BUTTON_ADDR(7796) // 8192 - 6 * 64 - 12
)
button_controller(
    .clk(clk),
    .reset(resume),
    .copy_start(copy_start),
    .buttons_in({switches_p1[5:0], switches_p2[5:0]}),

    .mem_dout_we(bc_mem_dout_we),
    .mem_dout_addr(bc_mem_dout_addr),
    .mem_dout(bc_mem_dout)
);

/*
    cpu
*/

wire [CODE_WIDTH-1:0] program_memory_addr_bus;
wire [15:0] program_memory_data_bus;
wire data_memory_write_we_bus;
wire [DATA_WIDTH-1:0] data_memory_write_addr_bus;
wire [15:0] data_memory_write_data_bus;
wire [DATA_WIDTH-1:0] data_memory_read_addr_bus;
wire [15:0] data_memory_read_data_bus;

wire cpu_mem_dout_we;
wire [DATA_WIDTH-1:0] cpu_mem_dout_addr;
wire [15:0] cpu_mem_dout;
wire [DATA_WIDTH-1:0] cpu_mem_din_addr;

wire [DATA_WIDTH-1:0] rc_controller_mem_din_addr;

cpu cpu(
    .clk(clk),
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
    .PROGRAM(0)
)
memory(
    .clk(clk),
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
    .clk(clk),
    .mem_dout_addr(program_memory_addr_bus),
    .mem_dout(program_memory_data_bus)
);
/* verilator lint_on PINMISSING */

/*
    rect copy controller
*/
wire [15:0] gpu_data;

rect_copy_controller rect_copy_controller(
    .clk(clk),
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
assign rgb = display_on ? {pixel_color[11], pixel_color[5], pixel_color[0]} : DEFAULT_COLOR;

gpu gpu(
    .pixel_clk(clk),
    .copy_start(copy_start),
    .reset(gpu_reset),
    
    .x_coord({6'b0, hpos}),
    .y_coord({6'b0, vpos}),
    .mem_din(gpu_data),
    .color(pixel_color)
);


endmodule
