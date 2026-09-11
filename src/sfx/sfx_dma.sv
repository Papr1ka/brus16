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

    // change OSC and start processing signal
    output reg shift,

    // inner memory interface
    output logic [15:0] mem_dout,
    output logic [2:0]  mem_dout_addr,
    output logic        mem_dout_we
);

// End of SFX memory address space in data memory.
localparam LAST_ADDR = DATA_ADDR_WIDTH'(SFX_MEM + VOICES * 4);

//                                   possible next states:
localparam WAIT_FOR_START = 0; // -> self / next (START)
localparam READ_ABS       = 1; // -> next
localparam READ_STEP      = 2; // -> next
localparam READ_AMP       = 3; // -> next
localparam READ_DECAY     = 4; // -> next
localparam SHIFT          = 5; // -> READ_ABS / WAIT_FOR_RESET
localparam WAIT_FOR_RESET = 6; // -> self (END)
reg   [2:0] state_counter;
logic [2:0] state_counter_new;

always_comb begin
    casez ({state_counter, copy, mem_din_addr >= LAST_ADDR})
        5'b000_0_?: state_counter_new = WAIT_FOR_START; // WAIT_FOR_START + !copy
        5'b000_1_?: state_counter_new = READ_ABS;       // WAIT_FOR_START + copy
        5'b101_?_0: state_counter_new = READ_ABS;       // SHIFT          + (wasn't last OSC)
        5'b101_?_1: state_counter_new = WAIT_FOR_RESET; // SHIFT          + (was last OSC)
        5'b110_?_?: state_counter_new = WAIT_FOR_RESET; // WAIT_FOR_RESET + ANY + ANY
        default:    state_counter_new = state_counter + 1;
    endcase
end


reg         reading_abs;
wire        reading_abs_new = (state_counter == READ_ABS)                 ? mem_din[0] : reading_abs;
reg  [15:0] abs_amp;
wire [15:0] abs_amp_new     = (state_counter == READ_AMP && reading_abs)  ? mem_din    : abs_amp;
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
    casez ({state_counter, copy})
        4'b110_?:  mem_din_addr_new = DATA_ADDR_WIDTH'(SFX_MEM);       // WAIT_FOR_RESET
        4'b000_0:  mem_din_addr_new = mem_din_addr;                    // WAIT_FOR_START + !copy  
        4'b100_?:  mem_din_addr_new = mem_din_addr;                    // READ_DECAY
        default:   mem_din_addr_new = mem_din_addr + 1;
    endcase
end

always_comb begin
    casez ({state_counter, reading_abs})
        4'b010_0: mem_dout = mul_result_shifted; // STEP + rel
        4'b010_1: mem_dout = mem_din;            // STEP + abs
        4'b011_0: mem_dout = mul_result_shifted; // AMP  + rel
        4'b011_1: mem_dout = mem_din;            // AMP  + abs
        4'b100_?: mem_dout = mem_din;            // DECAY
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
    case ({state_counter})
        READ_AMP:       mem_dout_we = update_amp;
        READ_DECAY:     mem_dout_we = 1;
        READ_STEP:      mem_dout_we = 1;
        default:        mem_dout_we = 0;
    endcase
end

wire shift_new = (state_counter == (SHIFT-1));

always_ff @(posedge clk) begin
    if (reset) begin
        mem_din_addr  <= DATA_ADDR_WIDTH'(SFX_MEM);
        shift         <= 0;
        state_counter <= WAIT_FOR_START;
        reading_abs   <= 0;
        abs_amp       <= 0;
        abs_step      <= 0;
    end else begin
        mem_din_addr  <= mem_din_addr_new;
        shift         <= shift_new;
        state_counter <= state_counter_new;
        reading_abs   <= reading_abs_new;
        abs_amp       <= abs_amp_new;
        abs_step      <= abs_step_new;
    end
end

endmodule
