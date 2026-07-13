/*
    DMA controller, copies rectangle data from data memory
    after copy_start signal to mem_dout bus (gpu)
    (starts on next tact)

    Recalculates relative coordinates to absolute in process

    3 clocks for each value

    clamped: [0, 640] for x, [0, 480] for y

    FOR I IN RANGE(4)
        SEND 16 clamped abs rect_left (48 clocks)
        WAIT 640 (640 clock)

    FOR I IN RANGE(4)
        SEND 16 clamped abs rect_right (48 clocks)
        WAIT 640 (640 clock)

    FOR I IN RANGE(4)
        SEND 16 clamped abs rect_top (48 clocks)
        WAIT 480 (480 clock)

    FOR I IN RANGE(4)
        SEND 16 clamped abs rect_bottom (48 clocks)
        WAIT 480 (480 clock)
    
    FOR I IN RANGE(4)
        SEND 16 colors (48 clocks)
        WAIT 16 (16 clock)

    Works in assumption, that after copy_start, it will be connected to data mem
    needs ~10_000 clocks for 64 rects
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

    output wire  [15:0]           mem_dout,      // data to gpu
    output wire  [2:0]            state_out,
    output wire  [9:0]            wait_counter_out,
    output wire  [3:0]            rect_counter_out,
    output wire  [1:0]            batch_counter_out,
    output wire                   batch_completed_out
);

// dout (xs | xs + width | ys | ys + width | colors)
reg   [15:0]      dout_reg;
logic [15:0]      dout_reg_new;
assign mem_dout = dout_reg;

// address to read from
reg   [ADDR_WIDTH-1:0] addr;
logic [ADDR_WIDTH-1:0] addr_new;


// general state (xs | xs + widths | ys | ys + widths | colors)
reg   [2:0] state;
logic [2:0] state_new;

localparam WAIT_FOR_START = 3'd0;
localparam READ_X = 3'd1;
localparam READ_WIDTH = 3'd2;
localparam READ_Y = 3'd3;
localparam READ_HEIGHT = 3'd4;
localparam READ_COLOR = 3'd5;

wire in_wait_for_start = state == WAIT_FOR_START;
wire in_read_x         = state == READ_X;
wire in_read_width     = state == READ_WIDTH;
wire in_read_height    = state == READ_HEIGHT;
wire in_read_color     = state == READ_COLOR;


// localstate to send any data (3 tacts for any coord or color)
reg   [1:0] localstate;
logic [1:0] localstate_new;

localparam CHECK_ABS = 2'd0;
localparam CALCULATE = 2'd1;
localparam SEND      = 2'd2;

wire in_send = localstate == SEND;

// inner batch rect counter
reg   [3:0] rect_counter;
logic [3:0] rect_counter_new;

// counter to wait for gpu will be ready for next batch
reg   [9:0] wait_counter;
logic [9:0] wait_counter_new;

// batch index (what batch of 64 rects (0-15 | 16-31 | 32-47 | 48-63))
reg   [1:0] batch_counter;
logic [1:0] batch_counter_new;

wire last_batch = batch_counter == 2'b11;

// when batch is sended and we are waiting
reg batch_completed;
reg batch_completed_new;

// abs / rel coords flag
reg   reading_abs;
logic reading_abs_new;

// register to store absolute coord
reg   [COORD_WIDTH-1:0] cursor_coord;
logic [COORD_WIDTH-1:0] cursor_coord_new;

// general register to store and process coord or color
reg   [COORD_WIDTH-1:0] buffer_reg;
logic [COORD_WIDTH-1:0] buffer_reg_new;

assign mem_din_addr = addr;

assign state_out = state;
assign wait_counter_out = wait_counter;
assign rect_counter_out = rect_counter;
assign batch_counter_out = batch_counter;
assign batch_completed_out = batch_completed;

// 10 bit comparator for wait_complete flag
wire [9:0]  to_compare = (in_read_x || in_read_width) ?
                            10'd640 :
                            (in_read_color ?
                                10'd16 :
                                10'd480);
wire        wait_complete = wait_counter_new >= to_compare;

always_comb begin
    casez ({in_wait_for_start, in_read_color, copy_start, (wait_complete && last_batch)})
        4'b1_0_1_?: state_new = READ_X;
        4'b0_1_?_1: state_new = WAIT_FOR_START;
        4'b0_0_?_1: state_new = state + 1;
        default:    state_new = state;
    endcase
end

always_comb begin
    casez ({in_wait_for_start, wait_complete, localstate})
        {1'b0, 1'b0, CHECK_ABS}: localstate_new = CALCULATE;
        {1'b0, 1'b0, CALCULATE}: localstate_new = SEND;
        {1'b0, 1'b0, SEND}:      localstate_new = CHECK_ABS;
        default:                 localstate_new = CHECK_ABS;
    endcase
end

always_comb begin
    casez ({in_send, wait_complete || batch_completed})
        2'b?1:   rect_counter_new = '0;
        2'b10:   rect_counter_new = rect_counter + 1;
        default: rect_counter_new = rect_counter;
    endcase
end

always_comb begin
    casez ({in_send && rect_counter == 4'd15, wait_complete})
        2'b?1:   batch_completed_new = 1'b0;
        2'b10:   batch_completed_new = 1'b1;
        default: batch_completed_new = batch_completed;
    endcase
end

always_comb begin
    case (wait_complete)
        1'b1: batch_counter_new = batch_counter + 1;
        default: batch_counter_new = batch_counter;
    endcase
end

always_comb begin
    case (batch_completed)
        1'b1:    wait_counter_new = wait_counter + 1;
        default: wait_counter_new = '0;
    endcase
end


// summator for address
wire  [ADDR_WIDTH-1:0] addr_sm_left = addr;
logic [ADDR_WIDTH-1:0] addr_sm_right;
assign addr_new = addr_sm_left + addr_sm_right;

wire [ADDR_WIDTH-1:0] addr_new_final = batch_completed_new ?
                                        (last_batch ?
                                            RECT_ADDR :
                                            addr
                                        ) :
                                        addr_new;

always_comb begin
    casez ({state, localstate, wait_complete})
        6'b000_??_0: addr_sm_right = copy_start ?
                                ADDR_WIDTH'(1) :
                                ADDR_WIDTH'(0);                     // WAIT_FOR_START
        6'b001_??_1,                                                // READ_X + wait_complete
        6'b101_01_0,                                                // READ_COLOR + CALC
        6'b001_10_0,                                                // READ_X + SEND
        6'b010_10_0: addr_sm_right = ADDR_WIDTH'(1);                // READ_WIDTH + SEND
        6'b010_??_1: addr_sm_right = (state_new == READ_Y ?
                                ADDR_WIDTH'(2) :
                                ADDR_WIDTH'(1));                    // READ_WIDTH + wait_complete
        6'b011_??_1,                                                // READ_Y + wait_complete
        6'b001_00_0,                                                // READ_X + CHECK
        6'b010_00_0,                                                // READ_WIDTH + CHECK
        6'b011_00_0,                                                // READ_Y + CHECK
        6'b100_00_0,                                                // READ_HEIGHT + CHECK
        6'b011_01_0,                                                // READ_Y + CALC
        6'b100_01_0,                                                // READ_HEIGHT + CALC
        6'b011_10_0,                                                // READ_Y + SEND
        6'b100_10_0: addr_sm_right = ADDR_WIDTH'(2);                // READ_HEIGHT + SEND
        6'b100_??_1: addr_sm_right = (state_new == READ_COLOR ?
                                ADDR_WIDTH'(5) :
                                ADDR_WIDTH'(2));                    // READ_HEIGHT + wait_complete
        6'b001_01_0,                                                // READ_X + CALC
        6'b010_01_0: addr_sm_right = ADDR_WIDTH'(3);                // READ_WIDTH + CALC
        6'b101_??_1,                                                // READ_COLOR + wait_complete
        6'b101_10_0: addr_sm_right = ADDR_WIDTH'(5);                // READ_COLOR + SEND
        default:     addr_sm_right = ADDR_WIDTH'(0);
    endcase
end

always_comb begin
    case (state != WAIT_FOR_START && localstate == CHECK_ABS)
        1'b1:    reading_abs_new = mem_din[0];
        default: reading_abs_new = reading_abs;
    endcase
end

always_comb begin
    case ({localstate == CALCULATE && reading_abs})
        1'b1:    cursor_coord_new = COORD_WIDTH'(mem_din);
        default: cursor_coord_new = cursor_coord;
    endcase
end

always_comb begin
    casez ({(in_read_width || in_read_height), localstate, (reading_abs || in_read_color)})
        4'b?_01_0: buffer_reg_new = mem_din + cursor_coord;
        4'b?_01_1: buffer_reg_new = mem_din;
        4'b1_10_?: buffer_reg_new = buffer_reg + mem_din;
        default:   buffer_reg_new = buffer_reg; 
    endcase
end

// coord clamp
wire  [15:0] constant = ((in_read_x || in_read_width) ? 16'd640 : 16'd480);
logic [9:0]  clamped;
wire gte = $signed(buffer_reg >= constant);

always_comb begin
    casez ({buffer_reg[15], gte})
        2'b1?:    clamped = 0;
        2'b01:    clamped = constant[9:0];
        default:  clamped = buffer_reg[9:0];
    endcase
end

always_comb begin
    case (in_read_color)
        1'b0:    dout_reg_new = {6'b0, clamped};
        default: dout_reg_new = buffer_reg;
    endcase
end

always_ff @(posedge clk) begin
    if (reset) begin
        cursor_coord    <= COORD_WIDTH'(0);
        buffer_reg      <= 16'b0;
        addr            <= ADDR_WIDTH'(RECT_ADDR);
        state           <= WAIT_FOR_START;
        reading_abs     <= 1'b0;
        dout_reg        <= 16'b0;
        rect_counter    <= '0;
        wait_counter    <= '0;
        batch_counter   <= '0;
        batch_completed <= 1'b0;
        localstate      <= CHECK_ABS;
    end else begin
        cursor_coord    <= cursor_coord_new;
        buffer_reg      <= buffer_reg_new;
        addr            <= addr_new_final;
        state           <= state_new;
        reading_abs     <= reading_abs_new;
        dout_reg        <= dout_reg_new;
        rect_counter    <= rect_counter_new;
        wait_counter    <= wait_counter_new;
        batch_counter   <= batch_counter_new;
        batch_completed <= batch_completed_new;
        localstate      <= localstate_new;
    end
end

endmodule
