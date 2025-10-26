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
    input   wire                    clk,
    input   wire                    reset,
    input   wire                    copy_start, // trigger to start copy in WAIT_FOR_COPY phase

    input   wire [COORD_WIDTH-1:0]  x_coord,
    input   wire [COORD_WIDTH-1:0]  y_coord,
    input   wire [15:0]             mem_din,    // abs rect data from copy controller
    output  wire [15:0]             color       // out color
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

wire [RECT_COUNT_WIDTH-1:0] fsm_dout_addr;
wire [15:0]                 fsm_dout;
wire [COORD_WIDTH-1:0]      fsm_dout_coords = COORD_WIDTH'(fsm_dout);

gpu_receiver_fsm gpu_receiver_fsm (
    .clk(clk),
    .reset(!(state == COPY)),
    .mem_din(mem_din),
    .finish(fsm_finish),
    .we_rect_lefts(we_rect_lefts),
    .we_rect_tops(we_rect_tops),
    .we_rect_rights(we_rect_rights),
    .we_rect_bottoms(we_rect_bottoms),
    .we_rect_colors(we_rect_colors),
    .dout_addr(fsm_dout_addr),
    .dout(fsm_dout)
);

// Rects memory
wire [COORD_WIDTH-1:0]      rect_lefts      [RECT_COUNT-1:0]; // xs
wire [COORD_WIDTH-1:0]      rect_tops       [RECT_COUNT-1:0]; // ys
wire [COORD_WIDTH-1:0]      rect_rights     [RECT_COUNT-1:0]; // xs + widths
wire [COORD_WIDTH-1:0]      rect_bottoms    [RECT_COUNT-1:0]; // ys + heights
wire [15:0]                 rect_colors     [RECT_COUNT-1:0]; // rect colors
reg  [RECT_COUNT_WIDTH-1:0] rect_idxs    [RECT_COUNT-1:0]; // 0 to 63, constants, read only

gpu_mem #(
    .ADDR_WIDTH(RECT_COUNT_WIDTH),
    .SIZE(RECT_COUNT),
    .DATA_WIDTH(COORD_WIDTH)
)
mem0 (
    .clk(clk),
    .we(we_rect_lefts),
    .mem_din_addr(fsm_dout_addr),
    .mem_din(fsm_dout_coords),
    .dout(rect_lefts) // xs
);

gpu_mem #(
    .ADDR_WIDTH(RECT_COUNT_WIDTH),
    .SIZE(RECT_COUNT),
    .DATA_WIDTH(COORD_WIDTH)
)
mem1 (
    .clk(clk),
    .we(we_rect_tops),
    .mem_din_addr(fsm_dout_addr),
    .mem_din(fsm_dout_coords),
    .dout(rect_tops) // ys
);

gpu_mem #(
    .ADDR_WIDTH(RECT_COUNT_WIDTH),
    .SIZE(RECT_COUNT),
    .DATA_WIDTH(COORD_WIDTH)
)
mem2 (
    .clk(clk),
    .we(we_rect_rights),
    .mem_din_addr(fsm_dout_addr),
    .mem_din(fsm_dout_coords),
    .dout(rect_rights) // xs + widths
);

gpu_mem #(
    .ADDR_WIDTH(RECT_COUNT_WIDTH),
    .SIZE(RECT_COUNT),
    .DATA_WIDTH(COORD_WIDTH)
)
mem3 (
    .clk(clk),
    .we(we_rect_bottoms),
    .mem_din_addr(fsm_dout_addr),
    .mem_din(fsm_dout_coords),
    .dout(rect_bottoms) // ys + heights
);

gpu_mem #(
    .ADDR_WIDTH(RECT_COUNT_WIDTH),
    .SIZE(RECT_COUNT),
    .DATA_WIDTH(16)
)
mem4 (
    .clk(clk),
    .we(we_rect_colors),
    .mem_din_addr(fsm_dout_addr),
    .mem_din(fsm_dout),
    .dout(rect_colors) // colors
);

// If collisions[i] is 1, than rect[i] collide with (coord_x, coord_y)
wire    [RECT_COUNT-1:0]        collisions;
reg     [RECT_COUNT-1:0]        collisions_buffer;  // for pipilining (better STA)
wire    [RECT_COUNT_WIDTH-1:0]  rect_idx;           // index of rect to display
wire    any_collision;
assign  color = any_collision ? rect_colors[rect_idx] : DEFAULT_COLOR;

// Comparators for each rect
generate
    genvar i;
    for (i = 0; i < RECT_COUNT; i++) begin
        comparator comp(
            .rect_left(rect_lefts[i]),
            .rect_top(rect_tops[i]),
            .rect_right(rect_rights[i]),
            .rect_bottom(rect_bottoms[i]),
            .coord_x(COORD_WIDTH'(x_coord)),
            .coord_y(COORD_WIDTH'(y_coord)),
            .collision(collisions[i])
        );
    end
endgenerate

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
        collisions_buffer   <= RECT_COUNT'(0);
    end else begin
        state               <= state_new;
        collisions_buffer   <= collisions;
    end
end

/* rect indices initialization */
initial begin
    for (integer j = 0; j < RECT_COUNT; j++) begin
        rect_idxs[j] = RECT_COUNT_WIDTH'(j);
    end
end

endmodule
