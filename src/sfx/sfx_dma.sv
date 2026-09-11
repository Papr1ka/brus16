/*
    SFX_DMA.
    This module implements the sfx_update function from the emulator.
    https://github.com/true-grue/Brus-16/blob/c644d52e16bc87efab1a996c2059f007db5c63e6/src/brus16_sfx.c#L103

    Function: Move the data for 16 oscillators from data memory
    to the sound synthesizer's internal memory (sfx_mem),
    converting all relative parameters to absolute values.
*/

module sfx_dma #(
    parameter VOICES = 16,
    parameter SFX_MEM = 7728,
    parameter DATA_ADDR_WIDTH = 13,
    parameter RATIO_BITS = 10
) (
    input  wire clk,
    input  wire reset,
    input  wire copy,

    // outer memory bus
    output reg  [DATA_ADDR_WIDTH-1:0] mem_din_addr, // data mem, read address
    input  wire [15:0]                mem_din,      // data mem, read data

    // change OSC signal
    output reg shift,

    // inner memory interface
    output logic [15:0] mem_dout,
    output logic [2:0]  mem_dout_addr,
    output logic        mem_dout_we
);

// End of SFX memory address space in data memory.
localparam LAST_ADDR = DATA_ADDR_WIDTH'(SFX_MEM + VOICES * 4);


//                copy                                          reset
//                 V                                             V
// wait_for_start -> operation cycle 16 times -> wait_for_reset -> wait_for_start

reg wait_for_start; // State: waiting for the copy signal to start operation
reg wait_for_reset; // State: end of operation, do nothing until reset
// Reset is needed to reset the registers

// (Operation) cyclic state_counter counter (0 -> 1 -> 2 -> 3 -> 4 -> 0 -> ...)
localparam READ_ABS       = 0;
localparam READ_STEP      = 1;
localparam READ_AMP       = 2;
localparam READ_DECAY     = 3;
localparam SHIFT          = 4;
reg   [2:0] state_counter;
logic [2:0] state_counter_new;

wire in_shift = state_counter == SHIFT;
wire in_wait  = wait_for_start || wait_for_reset;

wire wait_for_start_new = (wait_for_start && copy)                ? 0 : wait_for_start;
wire wait_for_reset_new = (in_shift && mem_din_addr >= LAST_ADDR) ? 1 : wait_for_reset;

always_comb begin
    if (!in_wait) begin
        if (in_shift) state_counter_new = READ_ABS;
        else          state_counter_new = state_counter + 1;
    end
    else              state_counter_new = state_counter;
end


reg         reading_abs;
wire        reading_abs_new = (state_counter == READ_ABS)                 ? mem_din[0] : reading_abs;
reg  [15:0] abs_amp;
wire [15:0] abs_amp_new     = (state_counter == READ_AMP  && reading_abs) ? mem_din    : abs_amp;
reg  [15:0] abs_step;
wire [15:0] abs_step_new    = (state_counter == READ_STEP && reading_abs) ? mem_din    : abs_step;

wire [15:0] mul_left           = (state_counter == READ_AMP) ? abs_amp : abs_step;
wire [15:0] mul_right          = mem_din;
wire [31:0] mul_result         = mul_left * mul_right;
wire [15:0] mul_result_shifted = 16'(mul_result >> RATIO_BITS);

wire update_amp_abs = (mem_din != 0);
wire update_amp_rel = (mul_result_shifted != 0);
wire update_amp     = reading_abs ? update_amp_abs : update_amp_rel;


logic [DATA_ADDR_WIDTH-1:0] mem_din_addr_new;

always_comb begin
    // Befora operation (wait_for_start + copy): increment addr
    if (wait_for_reset || (wait_for_start && !copy)) mem_din_addr_new = DATA_ADDR_WIDTH'(SFX_MEM);
    else begin
        // Before shift: do not increment addr for 1 clock
        if (state_counter == READ_DECAY)             mem_din_addr_new = mem_din_addr;
        else                                         mem_din_addr_new = mem_din_addr + 1;
    end
end

always_comb begin
    casez ({state_counter, reading_abs})
        4'b001_0: mem_dout = mul_result_shifted; // STEP + rel
        4'b001_1: mem_dout = mem_din;            // STEP + abs
        4'b010_0: mem_dout = mul_result_shifted; // AMP  + rel
        4'b010_1: mem_dout = mem_din;            // AMP  + abs
        4'b011_?: mem_dout = mem_din;            // DECAY
        default:  mem_dout = 0;
    endcase
end

always_comb begin
    case ({state_counter})
        READ_AMP:   mem_dout_addr = 1;
        READ_DECAY: mem_dout_addr = 2;
        READ_STEP:  mem_dout_addr = 3;
        default:    mem_dout_addr = 7;
    endcase
end

always_comb begin
    if (in_wait)        mem_dout_we = 0;
    else begin
        case ({state_counter})
            READ_AMP:   mem_dout_we = update_amp;
            READ_DECAY: mem_dout_we = 1;
            READ_STEP:  mem_dout_we = 1;
            default:    mem_dout_we = 0;
        endcase
    end
end

wire shift_new = !in_wait && (state_counter == (SHIFT-1));

always_ff @(posedge clk) begin
    if (reset) begin
        mem_din_addr   <= DATA_ADDR_WIDTH'(SFX_MEM);
        shift          <= 0;
        state_counter  <= READ_ABS;
        reading_abs    <= 0;
        abs_amp        <= 0;
        abs_step       <= 0;
        wait_for_start <= 1;
        wait_for_reset <= 0;
    end else begin
        mem_din_addr   <= mem_din_addr_new;
        shift          <= shift_new;
        state_counter  <= state_counter_new;
        reading_abs    <= reading_abs_new;
        abs_amp        <= abs_amp_new;
        abs_step       <= abs_step_new;
        wait_for_start <= wait_for_start_new;
        wait_for_reset <= wait_for_reset_new;
    end
end

endmodule
