`include "constants.svh"


module data_memory
#(
    parameter WIDTH = `DATA_ADDR_WIDTH,
    parameter SIZE  = `DATA_SIZE
)
(
    input  wire             clk,
    // r/w port 1
    input  wire [WIDTH-1:0] mem_addr_0, // r/w addr
    output reg  [15:0]      mem_dout_0, // read data
    input  wire             mem_we_0,   // write enable
    input  wire [15:0]      mem_din_0,  // write data

    // r/w port 2
    input  wire [WIDTH-1:0] mem_addr_1, // r/w addr
    output reg  [15:0]      mem_dout_1, // read data
    input  wire             mem_we_1,   // write enable
    input  wire [15:0]      mem_din_1   // write data
);

reg [15:0] data [SIZE-1:0];

// works with EDA 1.9.8.11 for TN9K
`ifdef TN9K
always_ff @(posedge clk) begin
    if (mem_we_0) begin
        data[mem_addr_0] <= mem_din_0;
    end
    mem_dout_0 <= data[mem_addr_0];
end

always_ff @(posedge clk) begin
    if (mem_we_1) begin
        data[mem_addr_1] <= mem_din_1;
    end
    mem_dout_1 <= data[mem_addr_1];
end
`endif

// works for TN20K, TP25K with latest EDA
`ifndef TN9K
always_ff @(posedge clk) begin
    if (mem_we_0) begin
        data[mem_addr_0] <= mem_din_0;
    end else begin
        mem_dout_0 <= data[mem_addr_0];
    end
end

always_ff @(posedge clk) begin
    if (mem_we_1) begin
        data[mem_addr_1] <= mem_din_1;
    end else begin
        mem_dout_1 <= data[mem_addr_1];
    end
end
`endif

initial begin
`ifdef SIM
    $readmemh("./firm/data.hex", data);
`endif
`ifndef SIM
    $readmemh("../firm/data.hex", data);
`endif
end

endmodule
