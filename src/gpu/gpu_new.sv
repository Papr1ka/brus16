/*
    GPU

    implemented for 64 rects
    step 0: recieve abs rect data from rect_copy_controller
        there are 6 arrays of memory for
        (rect_x, rect_y, rect_x+rect_width, rect_y+rect_height, color, rect_idx)
    step 1: 64 parallel comparators, checking that (x_coord, y_coord) collide with rect_{i},
        forming 64-bit array of collision flags
    step 2: 6-layer binary tree of mux-es
        one layer multiplex each pair of previous
        layer outputs according to collision flag of rect with highier z-index
        (It is assumed that rect_0 with rect_idx=0 has z_index=0)

        If RECT_COUNT == 2:
            rect_a = 0
            rect_b = 1
            collisions = [x, y]
            out = rect_b if y else rect_a
            (if y is 1, we must prefer rect_b (it has higher z-index) else rect_a)
        
        compose 6 layers: 64x32, 32x16, 16x8, 8x4, 4x2, 2x1
        now we get rect_idx that has the highest z-index and collide with (coord_x, coord_y)
        (if there was a collision at all)
        in parallel we maintain the any_collison = (collision[0] | collision[1] ...)
    step 3:
        if there was a collision (any_collision flag), color = colors[rect_idx] else default color
    All steps works asynchronously
*/

`include "constants.svh"


module gpu
#(
    parameter COORD_WIDTH       = `COORD_WIDTH,
    parameter RECT_COUNT        = `RECT_COUNT,
    parameter RECT_COUNT_WIDTH  = `RECT_COUNT_WIDTH,
    parameter DEFAULT_COLOR     = `DEFAULT_COLOR
)
(
    input   wire                     clk,
    input   wire                     reset,
    input   wire                     copy_start, // trigger to start copy in WAIT_FOR_COPY phase
    
    input  wire  [15:0]              mem_din,    // data from rect_copy controller
    input  wire  [2:0]               fsm_state,
    input  wire  [9:0]               coord_generator,
    input  wire  [3:0]               rect_counter,
    input  wire  [1:0]               batch_counter,
    input  wire                      batch_completed,

    input   wire  [COORD_WIDTH-1:0]  x_coord,
    input   wire  [COORD_WIDTH-1:0]  y_coord,
    output  logic [15:0]             color       // out color
);

// State machine to recieve data
reg     [1:0] state;
logic   [1:0] state_new;

localparam WAIT_FOR_COPY = 2'b00;
localparam COPY = 2'b01;
localparam EXECUTE = 2'b10;

// FSM to recieve new rect data from rect_copy_controller
wire fsm_finish;
wire we_rect_lefts;
wire we_rect_tops;
wire we_rect_rights;
wire we_rect_bottoms;
wire we_rect_colors;

wire [9:0]  fsm_dout_addr;
wire [63:0] fsm_dout;

wire [63:0] xs_mem_dout;
wire [63:0] ys_mem_dout;
wire [15:0] colors_mem_dout;

wire [1:0]  mem_select;
wire [9:0]  fsm_mem_din_addr;
wire [63:0] fsm_mem_din = (mem_select == 0) ? xs_mem_dout : ys_mem_dout;
wire        fsm_we;

reg  [5:0] rect_idxs [63:0];

gpu_receiver_fsm gpu_receiver_fsm (
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

wide_bram #(
    .ADDR_WIDTH(10),
    .SIZE(1024),
    .DATA_WIDTH(64)
)
xs_mem(
    .clk(clk),
    .mem_dout_addr(fsm_mem_din_addr),
    .mem_dout(xs_mem_dout),
    .we(fsm_we),
    .mem_din_addr(fsm_dout_addr),
    .mem_din(fsm_dout)
);

wide_bram #(
    .ADDR_WIDTH(10),
    .SIZE(1024),
    .DATA_WIDTH(64)
)
ys_mem(
    .clk(clk),
    .mem_dout_addr(fsm_mem_din_addr),
    .mem_dout(ys_mem_dout),
    .we(fsm_we),
    .mem_din_addr(fsm_dout_addr),
    .mem_din(fsm_dout)
);

wide_bram #(
    .ADDR_WIDTH(6),
    .SIZE(64),
    .DATA_WIDTH(16)
)
colors_mem(
    .clk(clk),
    .mem_dout_addr(),
    .mem_dout(colors_mem_dout),
    .we(fsm_we),
    .mem_din_addr(fsm_dout_addr[5:0]),
    .mem_din(fsm_dout[15:0])
);

// Binary tree of 6 mux layers
btree_mux btree_mux(
    .clk(clk),
    .flags_in(collisions_buffer),
    .data_in(rect_idxs),
    .flag_out(any_collision),
    .data_out(rect_idx)
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
    end else begin
        state               <= state_new;
    end
end

/* rect indices initialization */
initial begin
    for (integer j = 0; j < RECT_COUNT; j++) begin
        rect_idxs[j] = RECT_COUNT_WIDTH'(j);
    end
end

endmodule
