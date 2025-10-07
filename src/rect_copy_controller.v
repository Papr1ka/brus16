module rect_copy_controller
#(
    parameter COORD_WIDTH = 13,
    parameter RECT_ADDR = 8192 - 6 * 64,
    parameter ADDR_WIDTH = 13
)
(
    input clk,
    input reset,
    input copy_start,

    output wire [ADDR_WIDTH-1:0] mem_din_addr, // data mem, read address
    input wire [15:0] mem_din, // data mem, read data

    output reg [15:0] mem_dout, // logic data mem, write data
    output wire gpu_reset
);

assign gpu_reset = copy_start;

reg [ADDR_WIDTH-1:0] addr;
reg [ADDR_WIDTH-1:0] addr_new; // logic

reg [2:0] state;
reg [2:0] state_new;

reg reading_abs;
reg reading_abs_new; // logic

localparam WAIT_FOR_START = 3'd0;
localparam READ_ABS = 3'd1;
localparam READ_X = 3'd2;
localparam READ_Y = 3'd3;
localparam READ_WIDTH = 3'd4;
localparam READ_HEIGHT = 3'd5;
localparam READ_COLOR = 3'd6;

reg [COORD_WIDTH-1:0] cursor_x;
reg [COORD_WIDTH-1:0] cursor_x_new;
reg [COORD_WIDTH-1:0] cursor_y;
reg [COORD_WIDTH-1:0] cursor_y_new;

assign mem_din_addr = addr;

always @(*) begin
    casez ({state, copy_start, addr == 0})
        5'b000_0_?: state_new = WAIT_FOR_START;
        5'b000_1_?: state_new = READ_ABS;
        5'b110_?_0: state_new = READ_ABS;
        5'b110_?_1: state_new = WAIT_FOR_START;
        default: state_new = state + 1;
    endcase
end

always @(*) begin
    case ({state, copy_start})
        {WAIT_FOR_START, 1'b0}: addr_new = addr;
        default: addr_new = addr + 1;
    endcase
end

always @(*) begin
    case (state)
        READ_ABS: reading_abs_new = mem_din[0];
        default: reading_abs_new = reading_abs;
    endcase
end

always @(*) begin
    case ({state, reading_abs})
        {READ_X, 1'b1}: cursor_x_new = COORD_WIDTH'(mem_din);
        default: cursor_x_new = cursor_x;
    endcase
end

always @(*) begin
    case ({state, reading_abs})
        {READ_Y, 1'b1}: cursor_y_new = COORD_WIDTH'(mem_din);
        default: cursor_y_new = cursor_y;
    endcase
end

always @(*) begin
    casez ({state, reading_abs})
        4'b001_?: mem_dout = 16'b0; // READ_ABS
        4'b010_0: mem_dout = 16'(cursor_x + COORD_WIDTH'(mem_din)); // READ_X + rel
        4'b010_1: mem_dout = mem_din; // READ_X + abs
        4'b011_0: mem_dout = 16'(cursor_y + COORD_WIDTH'(mem_din)); // READ_Y + rel
        4'b011_1: mem_dout = mem_din; // READ_Y + abs
        4'b100_?,
        4'b101_?: mem_dout = 16'(COORD_WIDTH'(mem_din));
        4'b110_?: mem_dout = mem_din;
        default: mem_dout = 16'b0;
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        cursor_x <= COORD_WIDTH'(0);
        cursor_y <= COORD_WIDTH'(0);
        addr <= ADDR_WIDTH'(RECT_ADDR);
        state <= WAIT_FOR_START;
        reading_abs <= 1'b0;
    end else begin
        addr <= addr_new;
        state <= state_new;
        reading_abs <= reading_abs_new;
        cursor_x <= cursor_x_new;
        cursor_y <= cursor_y_new;
    end
end

initial begin
    cursor_x = COORD_WIDTH'(0);
    cursor_y = COORD_WIDTH'(0);
    addr = ADDR_WIDTH'(RECT_ADDR);
    state = WAIT_FOR_START;
    reading_abs = 1'b0;
end

endmodule
