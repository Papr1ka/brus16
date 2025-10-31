/*
    GPU
    color latency = 5 clocks
*/

`include "constants.svh"


module gpu
#(
    parameter DEFAULT_COLOR = `DEFAULT_COLOR
)
(
    input   wire                     clk,
    input   wire                     reset,
    input   wire                     copy_start, // trigger to start copy in WAIT_FOR_COPY phase
    
    // rect_copy_controller data
    input  wire  [15:0]              mem_din,
    input  wire  [2:0]               fsm_state,
    input  wire  [9:0]               coord_generator,
    input  wire  [3:0]               rect_counter,
    input  wire  [1:0]               batch_counter,
    input  wire                      batch_completed,

    // vga controller hpos, vpos
    input   wire  [9:0]              x_coord,
    input   wire  [9:0]              y_coord,

    // output color
    output  reg   [15:0]             color
);

// GPU state
reg     [1:0] state;
logic   [1:0] state_new;

localparam WAIT_FOR_COPY = 2'b00;
localparam COPY = 2'b01;
localparam EXECUTE = 2'b10;

// gpu memory output data
wire [63:0] xs_mem_dout;      // (rect_left < x <= rect_right)
wire [63:0] ys_mem_dout;      // (rect_top  < y <= rect_bottom)
wire [15:0] colors_mem_dout;  // rect color
reg  [5:0]  rect_idxs [63:0]; // rect indices, read only (0 to 63)

// FSM to recieve data from rect_copy_controller
wire fsm_finish;

// data to write
wire [9:0]  fsm_dout_addr;
wire [63:0] fsm_dout;
wire        fsm_we;

// which memory to write to (0=xs,1=ys,2=colors)
wire [1:0]  mem_select;

// data to read
wire [9:0]  fsm_mem_din_addr;
wire [63:0] fsm_mem_din = (mem_select == 0) ? xs_mem_dout : ys_mem_dout;

gpu_receiver_fsm gpu_receiver_fsm(
    .clk(clk),
    .reset(!(state == COPY)),
    .din(mem_din),
    .state(fsm_state),
    .coord_generator(coord_generator),
    .rect_counter(rect_counter),
    .batch_counter(batch_counter),
    .batch_completed(batch_completed),
    .mem_select(mem_select),
    .mem_din_addr(fsm_mem_din_addr),
    .mem_din(fsm_mem_din),
    .we(fsm_we),
    .dout_addr(fsm_dout_addr),
    .dout(fsm_dout),
    .finish(fsm_finish)
);

wire [9:0] xs_read_addr = state == COPY ? fsm_mem_din_addr : x_coord;
wire [9:0] ys_read_addr = state == COPY ? fsm_mem_din_addr : y_coord;
wire       xs_we        = fsm_we && mem_select == 0;
wire       ys_we        = fsm_we && mem_select == 1;
wire       colors_we    = fsm_we && mem_select == 2;

gpu_bram #(
    .ADDR_WIDTH(10),
    .SIZE(1024),
    .DATA_WIDTH(64),
    .COLLISIONS(1)
)
xs_mem(
    .clk(clk),
    .mem_dout_addr(xs_read_addr),
    .mem_dout(xs_mem_dout),
    .we(xs_we),
    .mem_din_addr(fsm_dout_addr),
    .mem_din(fsm_dout)
);

gpu_bram #(
    .ADDR_WIDTH(10),
    .SIZE(1024),
    .DATA_WIDTH(64),
    .COLLISIONS(1)
)
ys_mem(
    .clk(clk),
    .mem_dout_addr(ys_read_addr),
    .mem_dout(ys_mem_dout),
    .we(ys_we),
    .mem_din_addr(fsm_dout_addr),
    .mem_din(fsm_dout)
);

reg  [5:0]  rect_idx;
wire [5:0]  rect_idx_new;
reg  [1:0]  any_collision_delay;
wire        any_collision_new;
wire [15:0] color_new = any_collision_delay[1] ? colors_mem_dout : DEFAULT_COLOR;

gpu_bram #(
    .ADDR_WIDTH(6),
    .SIZE(64),
    .DATA_WIDTH(16),
    .COLLISIONS(0)
)
colors_mem(
    .clk(clk),
    .mem_dout_addr(rect_idx),
    .mem_dout(colors_mem_dout),
    .we(colors_we),
    .mem_din_addr(fsm_dout_addr[5:0]),
    .mem_din(fsm_dout[15:0])
);

// (rect_left < x <= rect_right) && (rect_top  < y <= rect_bottom)
reg   [63:0] collisions_buffer;
wire  [63:0] collisions_buffer_new = xs_mem_dout & ys_mem_dout;

// Binary tree of 6 mux layers
btree_mux btree_mux(
    .clk(clk),
    .flags_in(collisions_buffer),
    .data_in(rect_idxs),
    .flag_out(any_collision_new),
    .data_out(rect_idx_new)
);

always_comb begin
    casez ({state, copy_start, fsm_finish})
        4'b000?: state_new = WAIT_FOR_COPY;    // WAIT_FOR_COPY
        4'b001?,                               // WAIT_FOR_COPY + copy_start
        4'b01?0: state_new = COPY;             // COPY + !fsm_finish
        4'b01?1,                               // COPY + fsm_finish
        4'b10??: state_new = EXECUTE;          // EXECUTE
        default: state_new = WAIT_FOR_COPY;
    endcase
end

// Sequential logic
always_ff @(posedge clk) begin
    if (reset) begin
        state               <= WAIT_FOR_COPY;
        collisions_buffer   <= '0;
        rect_idx            <= '0;
        any_collision_delay <= '0;
        color               <= '0;
    end else begin
        state                   <= state_new;
        collisions_buffer       <= collisions_buffer_new;
        rect_idx                <= rect_idx_new;
        any_collision_delay     <= {any_collision_delay[0], any_collision_new};
        color                   <= color_new;
    end
end

/* rect indices initialization */
initial begin
    for (integer j = 0; j < 64; j++) begin
        rect_idxs[j] = 6'(j);
    end
end

endmodule
