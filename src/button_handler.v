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
reg button_out_new; // logic

always @(*) begin
    case (counter)
        COUNTER_VALUE: button_out_new = 1'b1;
        default: button_out_new = button_out;
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        counter <= COUNTER_SIZE'(0);
        button_out <= 1'b0;
    end else if (!button_in) begin
        counter <= COUNTER_SIZE'(0);
        button_out <= button_out_new;
    end else begin
        counter <= counter + 1;
        button_out <= button_out_new;
    end
end

initial begin
    counter = COUNTER_SIZE'(0);
    button_out = 1'b0;
end

endmodule
