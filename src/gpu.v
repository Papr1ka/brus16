// latency = 6 clocks (when x = 0, color for x = 0 will be at x = 6)

module gpu
#(
    parameter COORD_WIDTH = 16
)
(
    input wire pixel_clk, // pixel clock when calculating or cpu clock when copy
    input wire reset,
    input wire copy_start, // trigger to start copy in WAIT_FOR_COPY phase

    input wire [COORD_WIDTH-1:0] x_coord,
    input wire [COORD_WIDTH-1:0] y_coord,
    input wire [15:0] mem_din, // rect data from cpu
    output wire [15:0] color
);

parameter RECT_COUNT = 64;
parameter RECT_COUNT_WIDTH = 6;
parameter DEFAULT_COLOR = 16'b1111100000000000;

// rect memory
reg [COORD_WIDTH-1:0] rect_lefts [RECT_COUNT-1:0]; // xs
reg [COORD_WIDTH-1:0] rect_tops [RECT_COUNT-1:0]; // ys
reg [COORD_WIDTH-1:0] rect_rights [RECT_COUNT-1:0]; // xs + widths
reg [COORD_WIDTH-1:0] rect_bottoms [RECT_COUNT-1:0]; // ys + heights
reg [15:0] rect_colors [RECT_COUNT-1:0]; // rect colors
reg [RECT_COUNT_WIDTH-1:0] rect_idxs [RECT_COUNT-1:0]; // 0 to 63
// 

// if collisions[i] is 1, than rect[i] collide with (coord_x, coord_y)
wire [RECT_COUNT-1:0] collisions;
wire [RECT_COUNT_WIDTH-1:0] rect_idx; // index of rect to display
wire any_collision;
assign color = any_collision ? rect_colors[rect_idx] : DEFAULT_COLOR;

// state machine to recieve data
reg [1:0] state;
reg [1:0] state_new; // logic
localparam WAIT_FOR_COPY = 2'b00;
localparam COPY = 2'b01;
localparam EXECUTE = 2'b10;

reg [2:0] copy_state;
reg [2:0] copy_state_new; // logic
localparam READ_START = 3'b000;
localparam READ_X = 3'b001;
localparam READ_Y = 3'b010;
localparam READ_WIDTH = 3'b011;
localparam READ_HEIGHT = 3'b100;
localparam READ_COLOR = 3'b101;

reg [RECT_COUNT_WIDTH-1:0] rect_counter;
reg [RECT_COUNT_WIDTH-1:0] rect_counter_new;
//

// comparators for each rect
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

// binary tree of 6 mux layers
btree_mux btree_mux(
    .clk(pixel_clk),
    .flags_in(collisions),
    .data_in(rect_idxs),
    .flag_out(any_collision),
    .data_out(rect_idx)
);

always @(*) begin
    casez ({state, copy_state})
        5'b01000: copy_state_new = READ_X; // COPY + READ_START
        5'b01001: copy_state_new = READ_Y; // COPY + READ_X
        5'b01010: copy_state_new = READ_WIDTH; // COPY + READ_Y
        5'b01011: copy_state_new = READ_HEIGHT; // COPY + READ_WIDTH
        5'b01100: copy_state_new = READ_COLOR; // COPY + READ_HEIGHT
        5'b01101: copy_state_new = READ_START; // COPY + READ_COLOR
        5'b00???: copy_state_new = READ_START; // WAIT_FOR_COPY + ANY
        5'b10???: copy_state_new = READ_START; // EXECUTE + ANY
        default: copy_state_new = READ_START;
    endcase
end

always @(*) begin
    casez ({state, copy_state})
        5'b01101: rect_counter_new = rect_counter + 1; // COPY + READ_COLOR
        5'b00???: rect_counter_new = 0; // WAIT_FOR_COPY + ANY
        default: rect_counter_new = rect_counter;
    endcase
end

always @(*) begin
    casez ({state, copy_start, rect_counter == 6'b111111, copy_state == READ_COLOR})
        5'b000??: state_new = WAIT_FOR_COPY; // WAIT_FOR_COPY + 0 + ANY + ANY
        5'b001??: state_new = COPY; //  WAIT_FOR_COPY + 1 + ANY + ANY
        5'b01?11: state_new = EXECUTE; // COPY + ANY + 1 + 1
        5'b01?0?,
        5'b01?10: state_new = COPY; // COPY + ANY + 0 + ANY
        5'b10???: state_new = EXECUTE; // EXECUTE + ANY + ANY + ANY
        default: state_new = WAIT_FOR_COPY;
    endcase
end

always @(posedge pixel_clk) begin
    if (reset) begin
        state <= WAIT_FOR_COPY;
        copy_state <= READ_X;
        rect_counter <= 6'b0;
    end else begin
        rect_counter <= rect_counter_new;
        state <= state_new;
        copy_state <= copy_state_new;
        if (state == COPY) begin
            case (copy_state)
                READ_X: rect_lefts[rect_counter] <= COORD_WIDTH'(mem_din);
                READ_Y: rect_tops[rect_counter] <= COORD_WIDTH'(mem_din);
                READ_WIDTH: rect_rights[rect_counter] <= COORD_WIDTH'(mem_din) + rect_lefts[rect_counter];
                READ_HEIGHT: rect_bottoms[rect_counter] <= COORD_WIDTH'(mem_din) + rect_tops[rect_counter];
                READ_COLOR: rect_colors[rect_counter] <= mem_din;
            endcase
        end
    end
end

initial begin
    state = WAIT_FOR_COPY;
    copy_state = READ_X;
    rect_counter = 6'b0;
    for (integer j = 0; j < RECT_COUNT; j++) begin
        rect_lefts[j] = 16'b0;
        rect_tops[j] = 16'b0;
        rect_rights[j] = 16'b0;
        rect_bottoms[j] = 16'b0;
        rect_colors[j] = 16'b0;
        rect_idxs[j] = 6'(j);
    end
end

endmodule
