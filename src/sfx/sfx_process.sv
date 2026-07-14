module sfx_process #(
    parameter VOICES = 16,
    parameter DECAY_BITS = 6,
    parameter AMP_BITS = 15,
    parameter TABLE_BITS = 6
) (
    input  wire clk,
    input  wire reset,
    input  wire en,

    // sfx memory bus (writes new OSC values)
    output logic [15:0] mem_dout,
    output logic [2:0]  mem_dout_addr,
    output wire         mem_dout_we,
    output wire         shift,

    // Current OSC data
    input wire [15:0] curr_amp,
    input wire [15:0] curr_target_amp,
    input wire [15:0] curr_decay,
    input wire [15:0] curr_step,
    input wire [15:0] curr_phase,

    // output sample, valid after 16 shifts
    output reg  [15:0] sample,
    output reg         sample_valid
);

// stage after last shift counter
/*
6 clocks:
0: copy  curr    OSC step
1: write updated OSC phase
2: write updated OSC target_amp
3: write updated OSC amp
4: copy  curr    OSC decay
5: shift
*/
localparam CLOCKS_PER_OSC = 6;

reg  [2:0] stage_counter;
wire [2:0] stage_counter_new = (stage_counter == (CLOCKS_PER_OSC-1)) ? 0 : stage_counter + 1;
assign     shift             = (stage_counter == (CLOCKS_PER_OSC-1));

// shift counter (16 shifts => update decay_counter)
reg  [3:0] shift_counter;
wire [3:0] shift_counter_new = shift ? shift_counter + 1 : shift_counter;
wire       next_sample       = shift && (shift_counter == 4'(VOICES-1));

// decay counter related
reg  [5:0] decay_counter;
wire [5:0] decay_counter_new = next_sample ? decay_counter + 1 : decay_counter;
wire       is_decay          = decay_counter == 0;


// sfx_process logic
reg  [31:0] acc;

// new OSC values
reg  [15:0] curr_phase_updated;
reg  [15:0] curr_target_amp_updated;
reg  [15:0] curr_amp_updated;

reg  [15:0] amp_diff;

reg  [9:0]  pos;
wire [15:0] sin_wave;

reg [31:0] acc_diff;

sine_table sine_table(
    .clk(clk),
    .mem_dout_addr(pos),
    .mem_dout(sin_wave)
);

// amp related
wire [31:0] curr_target_amp_sext = {{16{curr_target_amp[15]}}, curr_target_amp[15:0]};
wire [31:0] curr_amp_sext        = {{16{curr_amp[15]}}, curr_amp[15:0]};
wire [15:0] amp_diff_new         = 16'((curr_target_amp_sext - curr_amp_sext) >>> DECAY_BITS);
wire [15:0] curr_amp_updated_new = curr_amp + amp_diff;

// acc related
wire [9:0]  pos_new = 10'(curr_phase >> TABLE_BITS);
wire [31:0] acc_diff_new = (32'($signed(sin_wave)) * $signed(curr_amp_updated)) >>> AMP_BITS;
wire [31:0] acc_new = next_sample ? 0 : (stage_counter == 3 ? acc + acc_diff : acc);

// phase related
wire [15:0] phase_new = curr_phase + curr_step;

// target amp related
wire [31:0] mul_result = (32'(curr_target_amp) * curr_decay);
wire [15:0] target_amp_new = is_decay ? 16'(mul_result >> AMP_BITS) : curr_target_amp;

// limit
wire [31:0] limited_left = $signed(acc) < $signed(-32768) ? $signed(-32768) : acc;
wire [15:0] sample_new = $signed(limited_left) > $signed(32767) ? 16'(32767) : 16'(limited_left);


// sfx memory bus logic
always_comb begin
    case (stage_counter)
        0:       mem_dout = curr_step;
        1:       mem_dout = curr_phase_updated;
        2:       mem_dout = curr_target_amp_updated;
        3:       mem_dout = curr_amp_updated;
        4:       mem_dout = curr_decay;
        default: mem_dout = 0;
    endcase
end

always_comb begin
    case (stage_counter)
        0:       mem_dout_addr = 3;
        1:       mem_dout_addr = 4;
        2:       mem_dout_addr = 1;
        3:       mem_dout_addr = 0;
        4:       mem_dout_addr = 2;
        default: mem_dout_addr = 0;
    endcase
end

assign mem_dout_we = (stage_counter <= 4);


always_ff @(posedge clk) begin
    if (reset) begin
        shift_counter           <= 0;
        decay_counter           <= 0;
        stage_counter           <= 0;

        amp_diff                <= 0;
        curr_amp_updated        <= 0;
        
        pos                     <= 0;
        acc_diff                <= 0;
        acc                     <= 0;

        curr_phase_updated      <= 0;

        curr_target_amp_updated <= 0;
        sample                  <= 0;
        sample_valid            <= 0;
    end else begin
        if (en) begin
            shift_counter           <= shift_counter_new;
            decay_counter           <= decay_counter_new;
            stage_counter           <= stage_counter_new;
            sample                  <= sample_new;
            sample_valid            <= next_sample;
        end

        amp_diff                <= amp_diff_new;
        curr_amp_updated        <= curr_amp_updated_new;
        
        pos                     <= pos_new;
        acc_diff                <= acc_diff_new;
        acc                     <= acc_new;

        curr_phase_updated      <= phase_new;

        curr_target_amp_updated <= target_amp_new;
    end
end

endmodule
