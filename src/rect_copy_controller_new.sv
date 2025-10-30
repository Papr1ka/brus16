/*
    DMA controller, copies rectangle data from data memory
    after copy_start signal to mem_dout bus (gpu)
    (starts on next tact)

    Recalculates relative coordinates to absolute in process

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

    output wire  [15:0]           mem_dout          // data mem, write data (to gpu)
);

// dout (xs | xs + width | ys | ys + width | colors)
reg   [15:0]      dout_reg;
assign mem_dout = dout_reg;

// address to read from
reg   [ADDR_WIDTH-1:0] addr;
logic [ADDR_WIDTH-1:0] addr_new;

// general state (xs | xs + widths | ys | ys + widths | colors)
reg   [2:0] state;
logic [2:0] state_new;

reg   [3:0] rect_counter;
logic [3:0] rect_counter_new;

// counter to wait for gpu will be ready for next batch
reg   [9:0] wait_counter;
logic [9:0] wait_counter_new;

// batch index (what batch of 64 rects (0-15 | 16-31 | 32-47 | 48-63))
reg   [1:0] batch_counter;
logic [1:0] batch_counter_new;

reg batch_completed;
reg batch_completed_new;

localparam WAIT_FOR_START = 3'd0;
localparam READ_X = 3'd1;
localparam READ_WIDTH = 3'd2;
localparam READ_Y = 3'd3;
localparam READ_HEIGHT = 3'd4;
localparam READ_COLOR = 3'd5;

// localstate to send any data (3 tacts for any coord or color)
reg   [1:0] localstate;
logic [1:0] localstate_new;

localparam CHECK_ABS = 2'd0;
localparam CALCULATE = 2'd1;
localparam SEND      = 2'd2;

// abs / rel coords flag
reg   reading_abs;
logic reading_abs_new;

// register to store absolute coord
reg   [COORD_WIDTH-1:0] cursor_coord;
logic [COORD_WIDTH-1:0] cursor_coord_new;

reg   [COORD_WIDTH-1:0] coord_reg;
logic [COORD_WIDTH-1:0] coord_reg_new;

assign mem_din_addr = addr;

assign wait_complete = (state == READ_X || state == READ_WIDTH) ?
                        wait_counter_new >= 640 :
                        (state == READ_COLOR) ?
                            wait_counter_new >= 16:
                            wait_counter_new >= 480;

always_comb begin
    casez ({state == WAIT_FOR_START, state == READ_COLOR, copy_start, wait_complete && batch_counter == 2'b11})
        4'b1_0_1_?: state_new = READ_X;
        4'b0_1_?_1: state_new = WAIT_FOR_START;
        4'b0_0_?_1: state_new = state + 1;
        default:    state_new = state;
    endcase
end

always_comb begin
    casez ({state == WAIT_FOR_START, wait_complete, localstate})
        {1'b0, 1'b0, CHECK_ABS}: localstate_new = CALCULATE;
        {1'b0, 1'b0, CALCULATE}: localstate_new = SEND;
        {1'b0, 1'b0, SEND}:      localstate_new = CHECK_ABS;
        default:                 localstate_new = CHECK_ABS;
    endcase
end

always_comb begin
    casez ({localstate == SEND, wait_complete || batch_completed})
        2'b?1:   rect_counter_new = '0;
        2'b10:   rect_counter_new = rect_counter + 1;
        default: rect_counter_new = rect_counter;
    endcase
end

always_comb begin
    casez ({localstate == SEND && rect_counter == 4'd15, wait_complete})
        2'b?1:   batch_completed_new = 1'b0;
        2'b10:   batch_completed_new = 1'b1;
        default: batch_completed_new = batch_completed;
    endcase
end

always_comb begin
    if (wait_complete) batch_counter_new = batch_counter + 1;
    else               batch_counter_new = batch_counter;
end

always_comb begin
    if (batch_completed) wait_counter_new = wait_counter + 1;
    else                 wait_counter_new = '0;
end

always_comb begin
    casez ({state, localstate, wait_complete})
        6'b000_??_0: addr_new = addr + copy_start;       // WAIT_FOR_START
        6'b001_??_1: addr_new = addr + 1;   // READ_X + wait_complete
        6'b010_??_1: addr_new = addr + 1 + (state_new == READ_Y);   // READ_WIDTH + wait_complete
        6'b011_??_1: addr_new = addr + 2;   // READ_Y + wait_complete
        6'b100_??_1: addr_new = addr + 2 + (state_new == READ_COLOR ? 3 : 0);   // READ_HEIGHT + wait_complete
        6'b101_??_1: addr_new = addr + 5;   // READ_COLOR + wait_complete
        6'b001_00_0,                        // READ_X + CHECK
        6'b010_00_0,                        // READ_WIDTH + CHECK
        6'b011_00_0,                        // READ_Y + CHECK
        6'b100_00_0,                        // READ_HEIGHT + CHECK
        6'b011_01_0,                        // READ_Y + CALC
        6'b100_01_0: addr_new = addr + 2;   // READ_HEIGHT + CALC
        6'b001_01_0,                        // READ_X + CALC
        6'b010_01_0: addr_new = addr + 3;   // READ_WIDTH + CALC
        6'b101_00_0: addr_new = addr;       // READ_COLOR + CHECK
        6'b001_10_0,                        // READ_X + SEND
        6'b010_10_0: addr_new = addr + 1;   // READ_WIDTH + SEND
        6'b011_10_0,                        // READ_Y + SEND
        6'b100_10_0: addr_new = addr + 2;   // READ_HEIGHT + SEND
        6'b101_01_0: addr_new = addr + 1;   // READ_COLOR + CALC
        6'b101_10_0: addr_new = addr + 5;   // READ_COLOR + SEND
        default:     addr_new = addr;
    endcase
end

always_comb begin
    case (state != WAIT_FOR_START && localstate == CHECK_ABS)
        1'b1: reading_abs_new = mem_din[0];
        default: reading_abs_new = reading_abs;
    endcase
end

always_comb begin
    case ({localstate, reading_abs})
        {CALCULATE, 1'b1}: cursor_coord_new = COORD_WIDTH'(mem_din);
        default:           cursor_coord_new = cursor_coord;
    endcase
end

always_comb begin
    casez ({state, localstate, reading_abs || state == READ_COLOR})
        6'b???_01_0: coord_reg_new = mem_din + cursor_coord;
        6'b???_01_1: coord_reg_new = mem_din;
        6'b010_10_?,
        6'b100_10_?: coord_reg_new = coord_reg + mem_din;
        default:   coord_reg_new = coord_reg; 
    endcase
end

always_ff @(posedge clk) begin
    if (reset) begin
        cursor_coord <= COORD_WIDTH'(0);
        coord_reg    <= 16'b0;
        addr         <= ADDR_WIDTH'(RECT_ADDR);
        state        <= WAIT_FOR_START;
        reading_abs  <= 1'b0;
        dout_reg     <= 16'b0;
        rect_counter <= '0;
        wait_counter <= '0;
        batch_counter <= '0;
        batch_completed <= 1'b0;
        localstate <= CHECK_ABS;
    end else begin
        cursor_coord <= cursor_coord_new;
        coord_reg    <= coord_reg_new;
        addr <= batch_completed_new ? (batch_counter == 2'b11 ? RECT_ADDR : addr) : addr_new;
        state        <= state_new;
        reading_abs  <= reading_abs_new;
        dout_reg     <= coord_reg;
        rect_counter <= rect_counter_new;
        wait_counter <= wait_counter_new;
        batch_counter <= batch_counter_new;
        batch_completed <= batch_completed_new;
        localstate <= localstate_new;
    end
end

endmodule
