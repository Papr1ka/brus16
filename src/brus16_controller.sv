/*
    Brus16 controller
    driven by vsync signal
        when vsync 0->1, frame render is ended, we can copy rect data
        when vsync 1->0, we can resume cpu work
        copy is a flag (holds for long)
        copy_start is a spike signal (holds for 1 tact)
        resume is a spike signal (holds for 1 tact)
        gpu_reset is a spike signal (holds for 1 tact)

        gpu_reset must be before copy_start!

        when copy, data memory will be connected to rect_copy_controller and button_controller
        when !copy, to the cpu
*/

`include "constants.svh"


module brus16_controller
(
    input   wire clk,
    input   wire reset,
    input   wire vsync,

    output  reg  copy_start, // start copy
    output  reg  copy,       // copy flag (drives memory muxes)
    output  wire resume,     // cpu continue
    output  wire gpu_reset   // gpu reset
);

assign resume    = !vsync && copy;
assign gpu_reset = vsync && !copy;

always_ff @(posedge clk) begin
    if (reset) begin
        copy <= 1'b0;
        copy_start <= 1'b0;
    end else begin
        copy <= vsync;
        copy_start <= gpu_reset;
    end
end

endmodule
