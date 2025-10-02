// `include "~/dev/brus16/src/defs.vh"

`define CODE_WIDTH 13
`define DATA_WIDTH 13

`define ADD 5'd0
`define SUB 5'd1
`define MUL 5'd2
`define AND 5'd3
`define OR 5'd4
`define XOR 5'd5
`define SHL 5'd6
`define SHR 5'd7
`define SHRA 5'd8
`define EQ 5'd9
`define LT 5'd10
`define LTU 5'd11
`define LOAD 5'd12
`define STORE 5'd13
`define LEA 5'd14
`define SET_FP 5'd15
`define JMP 5'd16
`define JZ 5'd17
`define JNZ 5'd18
`define CALL 5'd19
`define RET 5'd20
`define PUSH_LO 5'd21
`define PUSH_HI 5'd22
`define POP 5'd23


module alu(
    input wire [4:0] opcode,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [15:0] out
);

always @(*) begin
    casez (opcode)
        `ADD: out = a + b;
        `SUB: out = a - b;
        `MUL: out = $signed(a) * $signed(b);
        `AND: out = a & b;
        `OR: out = a | b;
        `XOR: out = a ^ b;
        `SHL: out = b[4] ? 0 : a << b[3:0];
        `SHR: out = b[4] ? 0 : a >> b[3:0];
        `SHRA: out = b[4] ? 0 : $signed(a) >> b[3:0];
        `EQ: out = 16'(a == b);
        `LT: out = 16'($signed(a) < $signed(b));
        `LTU: out = 16'(a < b);
        default: out = 16'b0;
    endcase
end

endmodule
