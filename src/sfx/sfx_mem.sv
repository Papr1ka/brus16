/*
OSC mem (shift registers):
                     OSC_16,        ..., OSC_2,        OSC_1/OSC_buff
addr: 0, amp        [amp_16,        ..., amp_2,        -> amp_1]
                                                       -> amp_buff
addr: 1, target_amp [target_amp_16, ..., target_amp_2, -> target_amp_1]
                                                       -> target_amp_buff
addr: 2, decay      [decay_16,      ..., decay_2,      -> decay_1]
                                                       -> decay_buff
addr: 3, step       [step_16,       ..., step_2,       -> step_1]
                                                       -> step_buff
addr: 4, phase      [phase_16,      ..., phase_2,      -> phase_1]
                                                       -> phase_buff
OSC_2 moves to both OSC_1 and OSC_buff.
OSC_buff moves to OSC_16.
write only to buff, cyclic shift right.
*/

module sfx_mem #(
    parameter VOICES = 16
) (
    input wire         clk,
    input wire         shift,

    input wire  [15:0] mem_din,
    input wire  [2:0]  mem_din_addr,
    input wire         mem_din_we,

    // OSC_BUFF
    output reg [15:0] curr_amp_buff,
    output reg [15:0] curr_target_amp_buff,
    output reg [15:0] curr_decay_buff,
    output reg [15:0] curr_step_buff,
    output reg [15:0] curr_phase_buff
) /*synthesis syn_srlstyle="distributed_ram"*/;

// Shift registers for each OSC parameter
reg [VOICES-1:0] [15:0] amp;
reg [VOICES-1:0] [15:0] target_amp;
reg [VOICES-1:0] [15:0] decay;
reg [VOICES-1:0] [15:0] step;
reg [VOICES-1:0] [15:0] phase;


always_ff @(posedge clk) begin
    if (shift) begin
        for (integer i = 0; i < VOICES; i = i + 1) begin
            amp       [i] <= amp       [(i + 1) % VOICES];
            target_amp[i] <= target_amp[(i + 1) % VOICES];
            decay     [i] <= decay     [(i + 1) % VOICES];
            step      [i] <= step      [(i + 1) % VOICES];
            phase     [i] <= phase     [(i + 1) % VOICES];
        end
        curr_amp_buff        <= amp       [1];
        curr_target_amp_buff <= target_amp[1];
        curr_decay_buff      <= decay     [1];
        curr_step_buff       <= step      [1];
        curr_phase_buff      <= phase     [1];
    end else if (mem_din_we) begin
        case (mem_din_addr)
            0: amp       [0] <= mem_din;
            1: target_amp[0] <= mem_din;
            2: decay     [0] <= mem_din;
            3: step      [0] <= mem_din;
            4: phase     [0] <= mem_din;
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
