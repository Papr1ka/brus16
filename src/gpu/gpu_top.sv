/*
    GPU top module
*/

`include "constants.svh"

module gpu_top
#(
    parameter DATA_ADDR_WIDTH = `DATA_ADDR_WIDTH,
    parameter DEFAULT_COLOR   = `DEFAULT_COLOR
)
(
    input  wire                       clk,
    input  wire                       reset,
    input  wire [1:0]                 peripheral_sel,
    input  wire                       rc_controller_pulse,
    input  wire                       gpu_pulse,

    // rect_copy_controller data memory bus
    input  wire [15:0]                mem_din,
    output wire [DATA_ADDR_WIDTH-1:0] mem_din_addr,

    // vga_controller signals
    input  wire [9:0]                 hpos,
    input  wire [9:0]                 vpos,
    input  wire                       display_on,
    
    // delayed rgb (5 clocks)
    output wire [15:0]                rgb
);

wire [15:0] gpu_data;
wire [2:0]  state;
wire [9:0]  wait_counter;
wire [3:0]  rect_counter;
wire [1:0]  batch_counter;
wire        batch_completed;

rect_copy_controller copy_controller(
    .clk(clk),
    .reset(reset | (peripheral_sel == 2'd1)),
    .copy_start(rc_controller_pulse),

    // to data memory
    .mem_din(mem_din),
    .mem_din_addr(mem_din_addr),

    // to gpu
    .mem_dout(gpu_data),
    .state_out(state),
    .wait_counter_out(wait_counter),
    .rect_counter_out(rect_counter),
    .batch_counter_out(batch_counter),
    .batch_completed_out(batch_completed)
);

wire [15:0] pixel_color; // rgb 5 6 5
assign rgb = display_on ? pixel_color : DEFAULT_COLOR;

gpu gpu(
    .clk(clk),
    .reset(reset | gpu_pulse),
    .copy_start(rc_controller_pulse),

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

endmodule
