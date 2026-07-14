/*
    SFX top module

    sfx_controller generates audio_clk (44100 Hz), activates sfx_controller and sfx_process
    sfx_dma represents sfx_update function (copy 16 OSC parameters from data memory to sfx_mem)
    sfx_process represents sfx_process function (generate new sample)
    sfx_mem holds 16 OSC parameters + buffer for 1 OSC to write updated values
    sine_table is a 1024 16-bit sine table
*/

`include "constants.svh"

module sfx_top #(
    parameter VOICES = `VOICES,
    parameter SFX_MEM = `SFX_MEM,
    parameter DATA_ADDR_WIDTH = `DATA_ADDR_WIDTH,
    parameter RATIO_BITS = `RATIO_BITS,
    parameter DECAY_BITS = `DECAY_BITS,
    parameter AMP_BITS = `AMP_BITS,
    parameter TABLE_BITS = `TABLE_BITS
) (
    input  wire                       clk,
    input  wire                       reset,
    input  wire                       copy,
    input  wire                       copy_pulse,

    // outer memory bus
    output wire [DATA_ADDR_WIDTH-1:0] mem_din_addr,   // data mem, read address
    input  wire [15:0]                mem_din,        // data mem, read data

    output reg [15:0]                 sample_out,     // output sample
    output wire                       audio_clk       // audio clk, 44100 Hz
);

localparam PROCESS_CLOCKS_PER_SAMPLE = 96;

wire dma_start;
wire process_en;

sfx_controller #(
    .PROCESS_CLOCKS_PER_SAMPLE(PROCESS_CLOCKS_PER_SAMPLE)
) sfx_controller(
    .clk(clk),
    .reset(reset),
    .copy(copy),

    .process_en(process_en),
    .dma_start(dma_start),

    .audio_clk(audio_clk)
);

// current OSC data
wire [15:0] curr_amp;
wire [15:0] curr_target_amp;
wire [15:0] curr_decay;
wire [15:0] curr_step;
wire [15:0] curr_phase;

// dma sfx memory interface
wire        dma_shift;
wire [15:0] dma_mem_dout;
wire [2:0]  dma_mem_dout_addr;
wire        dma_mem_dout_we;

sfx_dma #(
    .VOICES(VOICES),
    .SFX_MEM(SFX_MEM),
    .DATA_ADDR_WIDTH(DATA_ADDR_WIDTH),
    .RATIO_BITS(RATIO_BITS)
) sfx_dma(
    .clk(clk),
    .reset(reset | copy_pulse),
    .copy(dma_start),
    
    .mem_din_addr(mem_din_addr),
    .mem_din(mem_din),
    
    .shift(dma_shift),
    .mem_dout(dma_mem_dout),
    .mem_dout_addr(dma_mem_dout_addr),
    .mem_dout_we(dma_mem_dout_we),

    .curr_target_amp(curr_target_amp),
    .curr_amp(curr_amp),
    .curr_phase(curr_phase)
);

// process memory interface
wire        process_shift;
wire [15:0] process_mem_dout;
wire [2:0]  process_mem_dout_addr;
wire        process_mem_dout_we;

wire [15:0] sample;
wire        sample_valid;
wire [15:0] sample_out_new = sample_valid ? sample : sample_out;

sfx_process #(
    .VOICES(VOICES),
    .DECAY_BITS(DECAY_BITS),
    .AMP_BITS(AMP_BITS),
    .TABLE_BITS(TABLE_BITS)
) sfx_process(
    .clk(clk),
    .reset(reset),
    .en(process_en),
    
    .mem_dout(process_mem_dout),
    .mem_dout_addr(process_mem_dout_addr),
    .mem_dout_we(process_mem_dout_we),
    .shift(process_shift),

    .curr_amp(curr_amp),
    .curr_target_amp(curr_target_amp),
    .curr_decay(curr_decay),
    .curr_step(curr_step),
    .curr_phase(curr_phase),

    .sample(sample),
    .sample_valid(sample_valid)
);


// sfx memory bus
wire        sfx_shift        = process_en ? process_shift         : dma_shift;
wire [15:0] sfx_mem_din      = process_en ? process_mem_dout      : dma_mem_dout;
wire [2:0]  sfx_mem_din_addr = process_en ? process_mem_dout_addr : dma_mem_dout_addr;
wire        sfx_mem_din_we   = process_en ? process_mem_dout_we   : dma_mem_dout_we;

/*
OSC mem (shift registers):
                     BUFF             OSC_16,        ..., OSC_1
addr: 0, amp        [amp_buff,        amp_16,        ..., amp_1]
addr: 1, target_amp [target_amp_buff, target_amp_16, ..., target_amp_1]
addr: 2, decay      [decay_buff,      decay_16,      ..., decay_1]
addr: 3, step       [step_buff,       step_16,       ..., step_1]
addr: 4, phase      [phase_buff,      phase_16,      ..., phase_1]
write only to buff, cyclic shift right
*/
sfx_mem #(
    .VOICES(VOICES + 1)
) sfx_mem(
    .clk(clk),
    .shift(sfx_shift),

    .mem_din(sfx_mem_din),
    .mem_din_addr(sfx_mem_din_addr),
    .mem_din_we(sfx_mem_din_we),

    .curr_amp(curr_amp),
    .curr_target_amp(curr_target_amp),
    .curr_decay(curr_decay),
    .curr_step(curr_step),
    .curr_phase(curr_phase)
);

always_ff @(posedge clk) begin
    if (reset) begin
        sample_out <= 0; 
    end else begin
        sample_out <= sample_out_new;
    end
end

endmodule
