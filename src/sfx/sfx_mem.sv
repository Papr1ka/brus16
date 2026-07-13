module sfx_mem #(
    parameter VOICES = 16
) (
    input wire         clk,
    input wire         shift,

    input wire  [15:0] mem_din,
    input wire  [2:0]  mem_din_addr,
    input wire         mem_din_we,

    output wire [15:0] curr_amp,
    output wire [15:0] curr_target_amp,
    output wire [15:0] curr_decay,
    output wire [15:0] curr_step,
    output wire [15:0] curr_phase
) /*synthesis syn_srlstyle="distributed_ram"*/;

reg [VOICES-1:0] [15:0] amp;
reg [VOICES-1:0] [15:0] target_amp;
reg [VOICES-1:0] [15:0] decay;
reg [VOICES-1:0] [15:0] step;
reg [VOICES-1:0] [15:0] phase;

assign curr_amp        = amp       [0];
assign curr_target_amp = target_amp[0];
assign curr_decay      = decay     [0];
assign curr_step       = step      [0];
assign curr_phase      = phase     [0];


always_ff @(posedge clk) begin
    if (shift) begin
        for (integer i = 0; i < VOICES; i = i + 1) begin
            amp       [i] <= amp       [(i + 1) % VOICES];
            target_amp[i] <= target_amp[(i + 1) % VOICES];
            decay     [i] <= decay     [(i + 1) % VOICES];
            step      [i] <= step      [(i + 1) % VOICES];
            phase     [i] <= phase     [(i + 1) % VOICES];
        end
    end else if (mem_din_we) begin
        case (mem_din_addr)
            0: amp       [VOICES-1] <= mem_din;
            1: target_amp[VOICES-1] <= mem_din;
            2: decay     [VOICES-1] <= mem_din;
            3: step      [VOICES-1] <= mem_din;
            4: phase     [VOICES-1] <= mem_din;
        endcase
    end
end

initial begin
    for (integer j = 0; j < VOICES; j++) begin
        amp[j]        = 0;
        target_amp[j] = 0;
        decay[j]      = 0;
        phase[j]      = 0;
        step[j]       = 0;
    end
end

endmodule
