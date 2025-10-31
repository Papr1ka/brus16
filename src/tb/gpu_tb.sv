module gpu_tb(
    input wire clk,
    input wire reset,
    input wire copy_start,
    input wire [9:0] x_coord,
    input wire [9:0] y_coord,
    output wire [15:0] color
);

parameter DATA_WIDTH = 13;

wire [DATA_WIDTH-1:0] read_addr;
wire [15:0] read_data;
wire [15:0] gpu_data;
wire gpu_reset;

bsram memory(
    .clk(clk),
    .mem_dout_addr(read_addr),
    .mem_dout(read_data)
);

wire  [2:0]  state;
wire  [9:0]  wait_counter;
wire  [3:0]  rect_counter;
wire  [1:0]  batch_counter;
wire         batch_completed;

rect_copy_controller controller(
    .clk(clk),
    .reset(reset),
    .copy_start(copy_start),

    .mem_din_addr(read_addr), // data mem, read address
    .mem_din(read_data), // data mem, read data

    .mem_dout(gpu_data), // data mem, write data
    .state_out(state),
    .wait_counter_out(wait_counter),
    .rect_counter_out(rect_counter),
    .batch_counter_out(batch_counter),
    .batch_completed_out(batch_completed)
);

gpu gpu(
    .clk(clk),
    .reset(reset),
    .copy_start(copy_start),

    .mem_din(gpu_data),
    .fsm_state(state),
    .coord_generator(wait_counter),
    .rect_counter(rect_counter),
    .batch_counter(batch_counter),
    .batch_completed(batch_completed),
    .x_coord(x_coord),
    .y_coord(y_coord),
    .color(colors)
);

endmodule
