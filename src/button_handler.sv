/*
    Button handler
    counter to 255 prevent button jarring
    counter resets to 0 when button_in signal is zero
    if counter reaches 255, set the button reg to 1 and do not change it until reset
*/

module button_handler
#(
    parameter COUNTER_SIZE = 8,
    parameter COUNTER_VALUE = 255
)
(
    input wire clk,
    input wire reset,

    input wire button_in,
    output reg button_out
);

reg [COUNTER_SIZE-1:0] counter;
logic button_out_new;

wire [COUNTER_SIZE-1:0] counter_new = button_in ? counter + 1 : COUNTER_SIZE'(0);

always_comb begin
    case (counter)
        COUNTER_VALUE: button_out_new = 1'b1;
        default: button_out_new = button_out;
    endcase
end

always_ff @(posedge clk) begin
    if (reset) begin
        counter <= COUNTER_SIZE'(0);
        button_out <= 1'b0;
    end else begin
        counter <= counter_new;
        button_out <= button_out_new;
    end
end


endmodule
