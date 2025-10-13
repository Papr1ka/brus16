/*
    Async alu, according to the ISA
*/

`include "constants.svh"


module alu(
    input wire [4:0] opcode,
    input wire [15:0] a,
    input wire [15:0] b,
    output logic [15:0] out
);

always_comb begin
    casez (opcode)
        `ADD: out = a + b;
        `SUB: out = a - b;
        `MUL: out = $signed(a) * $signed(b);
        `AND: out = a & b;
        `OR: out = a | b;
        `XOR: out = a ^ b;
        `SHL: out = b[4] ? 16'b0 : a << b[3:0];
        `SHR: out = b[4] ? 16'b0 : a >> b[3:0];
        `SHRA: out = b[4] ? 16'b0 : $signed(a) >> b[3:0];
        `EQ: out = {16{(a == b)}};
        `NEQ: out = {16{(a != b)}};
        `LT: out = {16{($signed(a) < $signed(b))}};
        `LE: out = {16{($signed(a) <= $signed(b))}};
        `GT: out = {16{($signed(a) > $signed(b))}};
        `GE: out = {16{($signed(a) >= $signed(b))}};
        `LTU: out = {16{(a < b)}};
        default: out = 16'b0;
    endcase
end

endmodule
