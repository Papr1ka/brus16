/*
    DMA controller, copies rectangle data from data memory
    after copy_start signal to mem_dout bus (gpu)
    (starts on next tact)

    Recalculates relative coordinates to absolute in process
    Sends packets of 6 (0, abs_x, abs_y, width, height, color) * 64 times
    Works in assumption, that after copy_start, it will be connected to data mem
    and gpu is in WAIT_FOR_COPY state (after reset)
*/

`include "constants.svh"


module rect_copy_controller
#(
    parameter COORD_WIDTH = 16,
    parameter RECT_ADDR   = `RECT_MEM,
    parameter ADDR_WIDTH  = `DATA_ADDR_WIDTH
)
(
    input wire                    clk,
    input wire                    reset,
    input wire                    copy_start,   // start copy?

    output wire  [ADDR_WIDTH-1:0] mem_din_addr, // data mem, read address
    input  wire  [15:0]           mem_din,      // data mem, read data

    output wire  [15:0]           mem_dout      // data mem, write data (to gpu)
);

reg   [15:0]      mem_dout_reg;
logic [15:0]      mem_dout_reg_new;
assign mem_dout = mem_dout_reg;

reg   [ADDR_WIDTH-1:0] addr;
logic [ADDR_WIDTH-1:0] addr_new;

reg   [2:0] state;
logic [2:0] state_new;

localparam WAIT_FOR_START = 3'd0;
localparam READ_ABS = 3'd1;
localparam READ_X = 3'd2;
localparam READ_Y = 3'd3;
localparam READ_WIDTH = 3'd4;
localparam READ_HEIGHT = 3'd5;
localparam READ_COLOR = 3'd6;

reg   reading_abs;
logic reading_abs_new;

reg   [COORD_WIDTH-1:0] cursor_x;
logic [COORD_WIDTH-1:0] cursor_x_new;
reg   [COORD_WIDTH-1:0] cursor_y;
logic [COORD_WIDTH-1:0] cursor_y_new;

assign mem_din_addr = addr;

always_comb begin
    casez ({state, copy_start, addr == 0})
        5'b000_0_?: state_new = WAIT_FOR_START; // WAIT_FOR_START
        5'b000_1_?: state_new = READ_ABS;       // WAIT_FOR_START + copy_start
        5'b110_?_0: state_new = READ_ABS;       // READ_COLOR + (wasn't last rect)
        5'b110_?_1: state_new = WAIT_FOR_START; // READ_COLOR + (was last rect)
        default:    state_new = state + 3'd1;
    endcase
end

always_comb begin
    case ({state, copy_start})
        {WAIT_FOR_START, 1'b0}: addr_new = addr;
        default:                addr_new = addr + 1;
    endcase
end

always_comb begin
    case (state)
        READ_ABS: reading_abs_new = mem_din[0];
        default:  reading_abs_new = reading_abs;
    endcase
end

always_comb begin
    case ({state, reading_abs})
        {READ_X, 1'b1}: cursor_x_new = COORD_WIDTH'(mem_din);
        default:        cursor_x_new = cursor_x;
    endcase
end

always_comb begin
    case ({state, reading_abs})
        {READ_Y, 1'b1}: cursor_y_new = COORD_WIDTH'(mem_din);
        default:        cursor_y_new = cursor_y;
    endcase
end

always_comb begin
    casez ({state, reading_abs})
        4'b001_?: mem_dout_reg_new = 16'b0;                             // READ_ABS
        4'b010_0: mem_dout_reg_new = cursor_x + COORD_WIDTH'(mem_din);  // READ_X + rel
        4'b011_0: mem_dout_reg_new = cursor_y + COORD_WIDTH'(mem_din);  // READ_Y + rel
        4'b010_1,                                                       // READ_X + abs
        4'b011_1,                                                       // READ_Y + abs
        4'b110_?: mem_dout_reg_new = mem_din;                           // READ COLOR
        4'b100_?,                                                       // READ_WIDTH
        4'b101_?: mem_dout_reg_new = COORD_WIDTH'(mem_din);             // READ_HEIGHT
        default:  mem_dout_reg_new = 16'b0;
    endcase
end

always_ff @(posedge clk) begin
    if (reset) begin
        cursor_x     <= COORD_WIDTH'(0);
        cursor_y     <= COORD_WIDTH'(0);
        addr         <= ADDR_WIDTH'(RECT_ADDR);
        state        <= WAIT_FOR_START;
        reading_abs  <= 1'b0;
        mem_dout_reg <= 16'b0;
    end else begin
        cursor_x     <= cursor_x_new;
        cursor_y     <= cursor_y_new;
        addr         <= addr_new;
        state        <= state_new;
        reading_abs  <= reading_abs_new;
        mem_dout_reg <= mem_dout_reg_new;
    end
end

endmodule
