`ifndef CONSTANTS
`define CONSTANTS

`define GOWIN // Uncomment for gowin
// `define VIVADO // Uncomment for vivado
// `define SIM // Uncomment for simulation (Icarus/Verilator)

// memory
`define CODE_ADDR_WIDTH 13
`define DATA_ADDR_WIDTH 13
`define CODE_SIZE (1 << `CODE_ADDR_WIDTH)
`define DATA_SIZE (1 << `DATA_ADDR_WIDTH)

`define RECT_COUNT_WIDTH 6
`define RECT_COUNT (1 << `RECT_COUNT_WIDTH)
`define COORD_WIDTH 16
`define DEFAULT_COLOR 16'b0

`define KEY_NUM 16
`define KEY_NUM_WIDTH 4
`define KEY_MEM `DATA_SIZE - `RECT_COUNT * 6 - `KEY_NUM
`define RECT_MEM `DATA_SIZE - `RECT_COUNT * 6

// cpu
`define STACK_DEPTH 6 // 64
`define RSTACK_DEPTH 5 // 32

`define JMP 2'd0
`define JZ 2'd1
`define CALL 2'd2
`define PUSH_ADDR 2'd3

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
`define NEQ 5'd10
`define LT 5'd11
`define LE 5'd12
`define GT 5'd13
`define GE 5'd14
`define LTU 5'd15
`define LOAD 5'd16
`define STORE 5'd17
`define LOCALS 5'd18
`define SET_FP 5'd19
`define ICALL 5'd20
`define RET 5'd21
`define PUSH_INT 5'd22
`define PUSH_MR 5'd23
`define POP 5'd24
`define WAIT 5'd25

`endif
