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
    input  wire [15:0] mem_din,      // data mem, read data

    // change OSC and start processing signal
    output reg shift,

    // inner memory interface
    output logic [15:0] mem_dout,
    output logic [2:0]  mem_dout_addr,
    output logic        mem_dout_we,

    input  wire  [15:0] curr_target_amp,
    input  wire  [15:0] curr_amp,
    input  wire  [15:0] curr_phase
);

localparam WAIT_FOR_START = 4'd0;
localparam READ_ABS = 4'd1;
localparam READ_STEP = 4'd2;
localparam READ_AMP = 4'd3;
localparam READ_DECAY = 4'd4;
localparam COPY_PHASE = 4'd5;
localparam COPY_AMP = 4'd6;
localparam DO_SHIFT = 4'd7;
localparam WAIT_FOR_RESET = 4'd8;

localparam LAST_ADDR = SFX_MEM + VOICES * 4;

reg   [3:0] state;
logic [3:0] state_new;

reg         reading_abs;
wire        reading_abs_new = (state == READ_ABS)                ?  mem_din[0] : reading_abs;
reg  [15:0] abs_amp;
wire [15:0] abs_amp_new     = (state == READ_AMP && reading_abs)  ? mem_din    : abs_amp;
reg  [15:0] abs_step;
wire [15:0] abs_step_new    = (state == READ_STEP && reading_abs) ? mem_din    : abs_step;

always_comb begin
    casez ({state, copy, mem_din_addr >= DATA_ADDR_WIDTH'(LAST_ADDR)})
        6'b0000_0_?: state_new = WAIT_FOR_START; // WAIT_FOR_START + 0   + ANY
        6'b0000_1_?: state_new = READ_ABS;       // WAIT_FOR_START + 1   + ANY
        6'b0111_?_0: state_new = READ_ABS;       // DO_SHIFT       + ANY + 0   (wasn't last rect)
        6'b0111_?_1: state_new = WAIT_FOR_RESET; // DO_SHIFT       + ANY + 1   (was last rect)
        6'b1000_?_?: state_new = WAIT_FOR_RESET; // WAIT_FOR_RESET + ANY + ANY
        default:     state_new = state + 1;
    endcase
end

logic [DATA_ADDR_WIDTH-1:0] mem_din_addr_new;

always_comb begin
    casez ({state, copy})
        5'b1000_?: mem_din_addr_new = DATA_ADDR_WIDTH'(SFX_MEM);       // WAIT_FOR_RESET + ANY
        5'b0000_0: mem_din_addr_new = mem_din_addr;                    // WAIT_FOR_START + 0  
        5'b0100_?: mem_din_addr_new = mem_din_addr;                    // READ_DECAY     + ANY
        5'b0101_?: mem_din_addr_new = mem_din_addr;
        5'b0110_?: mem_din_addr_new = mem_din_addr;
        default:   mem_din_addr_new = mem_din_addr + 1;
    endcase
end

wire [15:0] mul_left           = (state == READ_AMP) ? abs_amp : abs_step;
wire [15:0] mul_right          = mem_din;
wire [31:0] mul_result         = mul_left * mul_right;
wire [15:0] mul_result_shifted = 16'(mul_result >> RATIO_BITS);

wire [15:0] amp_new_abs = (mem_din != 0)            ? mem_din            : curr_target_amp;
wire [15:0] amp_new_rel = (mul_result_shifted != 0) ? mul_result_shifted : curr_target_amp;
wire [15:0] amp_new     = reading_abs               ? amp_new_abs        : amp_new_rel;

always_comb begin
    casez ({state, reading_abs})
        5'b0010_0: mem_dout = mul_result_shifted; // STEP + rel
        5'b0010_1: mem_dout = mem_din;            // STEP + abs
        5'b0011_0: mem_dout = amp_new;            // AMP  + rel
        5'b0011_1: mem_dout = amp_new;            // AMP  + abs
        5'b0100_?: mem_dout = mem_din;            // DECAY
        5'b0101_?: mem_dout = curr_phase;
        5'b0110_?: mem_dout = curr_amp;
        default:   mem_dout = 0;
    endcase
end

always_comb begin
    case ({state})
        READ_AMP:   mem_dout_addr = 1;
        READ_DECAY: mem_dout_addr = 2;
        READ_STEP:  mem_dout_addr = 3;
        COPY_AMP:   mem_dout_addr = 0;
        COPY_PHASE: mem_dout_addr = 4;
        default:    mem_dout_addr = 7;
    endcase
end

always_comb begin
    case ({state})
        READ_AMP:       mem_dout_we = 1;
        READ_DECAY:     mem_dout_we = 1;
        READ_STEP:      mem_dout_we = 1;
        COPY_AMP:       mem_dout_we = 1;
        COPY_PHASE:     mem_dout_we = 1;
        default:        mem_dout_we = 0;
    endcase
end

wire shift_new = (state == (DO_SHIFT-1));

always_ff @(posedge clk) begin
    if (reset) begin
        mem_din_addr <= DATA_ADDR_WIDTH'(SFX_MEM);
        shift        <= 0;
        state        <= WAIT_FOR_START;
        reading_abs  <= 0;
        abs_amp      <= 0;
        abs_step     <= 0;
    end else begin
        mem_din_addr <= mem_din_addr_new;
        shift        <= shift_new;
        state        <= state_new;
        reading_abs  <= reading_abs_new;
        abs_amp      <= abs_amp_new;
        abs_step     <= abs_step_new;
    end
end

endmodule
