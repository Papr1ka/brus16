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

module brus16_controller(
    input wire clk,
    input wire reset,
    input wire vsync,

    output wire copy_start, // start copy
    output wire copy, // copy flag (drives memory muxes)
    output wire resume, // cpu continue
    output wire gpu_reset // gpu reset
);

reg copy_reg;
logic copy_reg_new;

assign copy = copy_reg;
assign resume = !vsync && copy_reg;
assign gpu_reset = vsync && !copy_reg;
reg copy_start_reg; // delayed for 1 tact
assign copy_start = copy_start_reg;

always_comb begin
    case ({vsync, copy_reg})
        2'b10: copy_reg_new = 1'b1;
        2'b01: copy_reg_new = 1'b0;
        default: copy_reg_new = copy_reg;
    endcase
end

always_ff @(posedge clk) begin
    if (reset) begin
        copy_start_reg <= 1'b0;
        copy_reg <= 1'b0;
    end else begin
        copy_reg <= copy_reg_new;
        copy_start_reg <= gpu_reset;
    end
end

initial begin
    copy_start_reg = 1'b0;
    copy_reg = 1'b0;
end

endmodule
