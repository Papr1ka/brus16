`include "constants.svh"


module program_memory
#(
    parameter WIDTH = `CODE_ADDR_WIDTH,
    parameter SIZE  = `CODE_SIZE,
    parameter ROM_CORE = 0
)
(
    input  wire             clk,
    // read
    input  wire [WIDTH-1:0] mem_dout_addr,
    output reg  [15:0]      mem_dout,

    // write
    input  wire [WIDTH-1:0] mem_din_addr,
    input  wire [15:0]      mem_din,
    input  wire             mem_din_we
);

reg [15:0] data [SIZE-1:0];

always_ff @(posedge clk) begin
    if (mem_din_we) begin
        data[mem_din_addr] = mem_din;
    end
    mem_dout <= data[mem_dout_addr];
end

initial begin
`ifdef SIM
    if (ROM_CORE) begin
        $readmemh("./firm/code_rom.hex", data);    
    end else begin
        $readmemh("./firm/code.hex", data);
    end
`endif
`ifndef SIM
    if (ROM_CORE) begin
        $readmemh("../firm/code_rom.hex", data);    
    end else begin
        $readmemh("../firm/code.hex", data);
    end
`endif
end

endmodule
