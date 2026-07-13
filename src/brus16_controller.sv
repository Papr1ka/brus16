/*
    Brus16 controller
    driven by vsync signal
        when frame is rendered (vpos > 480), it's peripheral time
        when vsync 1->0, resume cpu work

        peripheral_sel is a flag (holds for long)
        *_pulse is a spike signal (holds for 1 tact)

        gpu_reset must be before rc_controller copy_start!

        cpu is always connected to data memory port 0
        peripheral_sel determines which peripheral is connected to data memory port 1
*/

`include "constants.svh"


module brus16_controller
(
    input   wire       clk,
    input   wire       reset,
    input   wire [9:0] vpos,

    // drives memory muxes on peripheral data bus
    output  reg [1:0]  peripheral_sel,

    // spile signals
    output  reg        cpu_pulse,               // cpu resume after wait
    output  reg        gpu_pulse,               // gpu reset
    output  reg        rc_controller_pulse,     // start rect_copy controller
    output  reg        button_controller_pulse, // start button controller
    output  reg        sfx_controller_pulse     // start sfx_controller copy
);

wire [1:0] peripheral_sel_new = vpos >= 509 && vpos < 523 ? 2'd0 : // rect copy controller
                                vpos >= 523 && vpos < 524 ? 2'd1 : // button controller
                                vpos == 524               ? 2'd2 : // sfx controller
                                2'd3;                              // any, but no writes

wire cpu_pulse_new               = (vpos == 0)   && peripheral_sel != 2'd3;
wire gpu_pulse_new               = (vpos == 509) && peripheral_sel != 2'd0;
wire rc_controller_pulse_new     = gpu_pulse; // only after gpu reset
wire button_controller_pulse_new = (vpos == 523) && peripheral_sel != 2'd1;
wire sfx_controller_pulse_new    = (vpos == 524) && peripheral_sel != 2'd2;

always_ff @(posedge clk) begin
    if (reset) begin
        peripheral_sel          <= 2'd3;
        cpu_pulse               <= 1'b0;
        gpu_pulse               <= 1'b0;
        rc_controller_pulse     <= 1'b0;
        button_controller_pulse <= 1'b0;
        sfx_controller_pulse    <= 1'b0;
    end else begin
        peripheral_sel          <= peripheral_sel_new;
        cpu_pulse               <= cpu_pulse_new;
        gpu_pulse               <= gpu_pulse_new;
        rc_controller_pulse     <= rc_controller_pulse_new;
        button_controller_pulse <= button_controller_pulse_new;
        sfx_controller_pulse    <= sfx_controller_pulse_new;
    end
end

endmodule
