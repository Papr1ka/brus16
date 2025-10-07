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
reg button_data;
reg button_data_new; // logic

always @(*) begin
    case (counter)
        COUNTER_VALUE: button_data_new = 1'b1;
        default: button_data_new = button_data;
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        counter <= COUNTER_SIZE'(0);
        button_data <= 1'b0;
    end else if (!button_in) begin
        counter <= COUNTER_SIZE'(0);
    end else begin
        counter <= counter + 1;
    end
end

endmodule