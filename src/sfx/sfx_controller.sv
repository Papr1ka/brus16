`include "constants.svh"

module sfx_controller #(
    parameter PROCESS_CLOCKS_PER_SAMPLE = 96
) (
    input  wire clk,
    input  wire reset,
    input  wire copy,

    output wire process_en,
    output wire dma_start,

    output reg  audio_clk
);

// 44100 Hz hard-coded
localparam SAMPLES_PER_FRAME = 735; // 44100 / 60

// clocks per sample = 420_000 / 735 (~571,43)
// 420_000 / 735 = 28_000 / 49 
localparam INC = 49;
localparam MOD = 28000;

reg  [14:0] phase_acc;
wire [14:0] phase_acc_inc = phase_acc + INC;
wire        reset_acc     = phase_acc_inc >= MOD;
wire [14:0] phase_acc_new = reset_acc ? phase_acc + (INC - MOD) : phase_acc_inc;

// processed samples per frame
reg  [9:0] samples_completed;
wire [9:0] samples_completed_new = reset_acc ? (samples_completed == (SAMPLES_PER_FRAME-1) ? 0 : samples_completed + 1) : samples_completed;

// per-sample counter (up to 735-736 clocks)
reg  [9:0] sample_counter;
wire [9:0] sample_counter_new = reset_acc ? 0 : sample_counter + 1;

// there is 735-736 clocks to process 1 sample
// 0-95 clocks -> sfx_process work
assign process_en = sample_counter < PROCESS_CLOCKS_PER_SAMPLE;
// 1 time per frame
// 734 processed + last sample processed (sample_counter >= PROCESS_CLOCKS_PER_SAMPLE) + copy time -> sfx_dma work
assign dma_start  = !process_en && copy && samples_completed == 734;

// 285 ~= 571.43/2
wire audio_clk_new = ((sample_counter == 0) || (sample_counter == 285)) ? ~audio_clk : audio_clk;

always_ff @(posedge clk) begin
    if (reset) begin
        sample_counter    <= 0;
        phase_acc         <= 0;
        samples_completed <= 0;
        audio_clk         <= 0;
    end else begin
        sample_counter    <= sample_counter_new;
        phase_acc         <= phase_acc_new;
        samples_completed <= samples_completed_new;
        audio_clk         <= audio_clk_new;
    end
end

endmodule
