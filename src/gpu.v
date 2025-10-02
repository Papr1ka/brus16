// latency = 6 clocks (when x = 0, color for x = 0 will be at x = 6)

module gpu
#(
    parameter COORD_WIDTH = 16
)
(
    input wire pixel_clk, // pixel clock when calculating or cpu clock when copy
    input wire reset,
    input wire we, // trigger to start copy in WAIT_FOR_COPY phase
    input wire idle, // trigger to change state to WAIT_FOR_COPY

    input wire [COORD_WIDTH-1:0] x_coord,
    input wire [COORD_WIDTH-1:0] y_coord,
    input wire [15:0] mem_din, // rect data from cpu
    output reg [15:0] color
);

parameter RECT_COUNT = 64;
parameter RECT_COUNT_WIDTH = 6;
parameter DEFAULT_COLOR = 16'b1111100000000000;
localparam LAST_RECT_INDEX = RECT_COUNT_WIDTH'(RECT_COUNT - 1);

reg [COORD_WIDTH-1:0] rect_left [RECT_COUNT-1:0]; // xs
reg [COORD_WIDTH-1:0] rect_top [RECT_COUNT-1:0]; // ys
reg [COORD_WIDTH-1:0] rect_right [RECT_COUNT-1:0]; // xs + widths
reg [COORD_WIDTH-1:0] rect_bottom [RECT_COUNT-1:0]; // ys + heights
reg [15:0] rect_color [RECT_COUNT-1:0]; // rect colors
reg [RECT_COUNT_WIDTH-1:0] rect_idx; // index of rect to display

// if collisions[i] is 1, than rect[i] collide with (coord_x, coord_y)
reg [RECT_COUNT-1:0] collisions;
reg no_collisions;
reg [15:0] color_to_display;
always @(posedge pixel_clk) begin
    no_collisions <= ~|collisions;
    color_to_display <= no_collisions ? DEFAULT_COLOR : rect_color[rect_idx];
end

// assign color_to_display = no_collisions ? DEFAULT_COLOR : rect_color[rect_idx];

reg [RECT_COUNT_WIDTH-1:0] rect_counter;
reg active; // is current rect active (when recieving)

wire [15:0] zero_or_data;
assign zero_or_data = active ? mem_din : 16'b0;

reg [2:0] state;
localparam WAIT_FOR_COPY = 3'b001;
localparam COPY = 3'b010;
localparam EXECUTE = 3'b100;

reg [2:0] copy_state;
localparam READ_ACTIVE = 3'd0;
localparam READ_X = 3'd1;
localparam READ_Y = 3'd2;
localparam READ_WIDTH = 3'd3;
localparam READ_HEIGHT = 3'd4;
localparam READ_COLOR = 3'd5;

generate
    genvar i;
    for (i = 0; i < RECT_COUNT; i++) begin
        comparator comp(
            .pixel_clk(pixel_clk),
            .rect_left(rect_left[i]),
            .rect_top(rect_top[i]),
            .rect_right(rect_right[i]),
            .rect_bottom(rect_bottom[i]),
            .coord_x(COORD_WIDTH'(x_coord)),
            .coord_y(COORD_WIDTH'(y_coord)),
            .collision(collisions[i])
        );
    end
endgenerate

priority_encoder64 encoder(
    .pixel_clk(pixel_clk),
    .to_encode(collisions),
    .encoded(rect_idx)
);

always @(posedge pixel_clk) begin
    if (reset) begin
        state <= WAIT_FOR_COPY;
    end
    else begin
        case (state)
            WAIT_FOR_COPY: begin
                if (we) begin
                    rect_counter <= 0;
                    state <= COPY;
                    copy_state <= READ_ACTIVE;
                end
            end
            COPY: begin
                case (copy_state)
                    READ_ACTIVE: begin
                        active <= mem_din[0];
                        copy_state <= READ_X;
                    end
                    READ_X: begin
                        rect_left[rect_counter] <= COORD_WIDTH'(zero_or_data);
                        copy_state <= READ_Y;
                    end
                    READ_Y: begin
                        rect_top[rect_counter] <= COORD_WIDTH'(zero_or_data);
                        copy_state <= READ_WIDTH;
                    end
                    READ_WIDTH: begin
                        rect_right[rect_counter] <= COORD_WIDTH'(zero_or_data) + rect_left[rect_counter];
                        copy_state <= READ_HEIGHT;
                    end
                    READ_HEIGHT: begin
                        rect_bottom[rect_counter] <= COORD_WIDTH'(zero_or_data) + rect_top[rect_counter];
                        copy_state <= READ_COLOR;
                    end
                    READ_COLOR: begin
                        rect_color[rect_counter] <= zero_or_data;
                        copy_state <= READ_ACTIVE;
                        if (rect_counter == (LAST_RECT_INDEX)) begin
                            state <= EXECUTE;
                            rect_counter <= 0;
                        end
                        else begin
                            state <= state;
                            rect_counter <= rect_counter + 1;
                        end
                    end
                    default: begin
                        copy_state <= READ_ACTIVE;
                    end
                endcase
            end
            EXECUTE: begin
                if (idle) begin
                    state <= WAIT_FOR_COPY;
                end
                else begin
                    color <= color_to_display;
                    state <= state;
                end
            end
            default: begin
                state <= WAIT_FOR_COPY;
            end
        endcase
    end
end

initial begin
    state = WAIT_FOR_COPY;
    rect_counter = 6'b0;
    copy_state = READ_ACTIVE;
    for (integer j = 0; j < RECT_COUNT; j++) begin
        rect_left[j] = 16'b0;
        rect_top[j] = 16'b0;
        rect_right[j] = 16'b0;
        rect_bottom[j] = 16'b0;
        rect_color[j] = 16'b0;
    end
end

endmodule
