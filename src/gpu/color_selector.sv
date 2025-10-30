`include "constants.svh"


module color_selector
#(
    parameter RECT_COUNT = `RECT_COUNT,
    parameter DEFAULT_COLOR = `DEFAULT_COLOR
)
(
    input  wire  [RECT_COUNT-1:0] collisions,
    input  wire  [15:0]           rect_colors [RECT_COUNT-1:0],
    output logic [15:0]           color
);

wire [RECT_COUNT-1:0] one_hot_addr = collisions & (-collisions);

/* 1296 LUT */
// always_comb begin
//     color = 'z;
//     for (int idx = 0; idx < RECT_COUNT; idx = idx + 1) begin
//         if (one_hot_addr == (1 << idx)) color = rect_colors[63 - idx];
//     end
//     if (one_hot_addr == 0) color = DEFAULT_COLOR;
// end

/* 1005 LUT */
// generate
//     genvar idx;
//     assign color = (~|one_hot_addr) ? DEFAULT_COLOR : 'z;
//     for (idx = 0; idx < RECT_COUNT; idx = idx + 1) begin
//         assign color = one_hot_addr[idx] ? rect_colors[63 - idx] : 'z;
//     end
// endgenerate

/* 919 LUT */
// always_comb begin
//     case (one_hot_addr)
//         1 << 0: color = rect_colors[0];
//         1 << 1: color = rect_colors[1];
//         1 << 2: color = rect_colors[2];
//         1 << 3: color = rect_colors[3];
//         1 << 4: color = rect_colors[4];
//         1 << 5: color = rect_colors[5];
//         1 << 6: color = rect_colors[6];
//         1 << 7: color = rect_colors[7];
//         1 << 8: color = rect_colors[8];
//         1 << 9: color = rect_colors[9];
//         1 << 10: color = rect_colors[10];
//         1 << 11: color = rect_colors[11];
//         1 << 12: color = rect_colors[12];
//         1 << 13: color = rect_colors[13];
//         1 << 14: color = rect_colors[14];
//         1 << 15: color = rect_colors[15];
//         1 << 16: color = rect_colors[16];
//         1 << 17: color = rect_colors[17];
//         1 << 18: color = rect_colors[18];
//         1 << 19: color = rect_colors[19];
//         1 << 20: color = rect_colors[20];
//         1 << 21: color = rect_colors[21];
//         1 << 22: color = rect_colors[22];
//         1 << 23: color = rect_colors[23];
//         1 << 24: color = rect_colors[24];
//         1 << 25: color = rect_colors[25];
//         1 << 26: color = rect_colors[26];
//         1 << 27: color = rect_colors[27];
//         1 << 28: color = rect_colors[28];
//         1 << 29: color = rect_colors[29];
//         1 << 30: color = rect_colors[30];
//         1 << 31: color = rect_colors[31];
//         1 << 32: color = rect_colors[32];
//         1 << 33: color = rect_colors[33];
//         1 << 34: color = rect_colors[34];
//         1 << 35: color = rect_colors[35];
//         1 << 36: color = rect_colors[36];
//         1 << 37: color = rect_colors[37];
//         1 << 38: color = rect_colors[38];
//         1 << 39: color = rect_colors[39];
//         1 << 40: color = rect_colors[40];
//         1 << 41: color = rect_colors[41];
//         1 << 42: color = rect_colors[42];
//         1 << 43: color = rect_colors[43];
//         1 << 44: color = rect_colors[44];
//         1 << 45: color = rect_colors[45];
//         1 << 46: color = rect_colors[46];
//         1 << 47: color = rect_colors[47];
//         1 << 48: color = rect_colors[48];
//         1 << 49: color = rect_colors[49];
//         1 << 50: color = rect_colors[50];
//         1 << 51: color = rect_colors[51];
//         1 << 52: color = rect_colors[52];
//         1 << 53: color = rect_colors[53];
//         1 << 54: color = rect_colors[54];
//         1 << 55: color = rect_colors[55];
//         1 << 56: color = rect_colors[56];
//         1 << 57: color = rect_colors[57];
//         1 << 58: color = rect_colors[58];
//         1 << 59: color = rect_colors[59];
//         1 << 60: color = rect_colors[60];
//         1 << 61: color = rect_colors[61];
//         1 << 62: color = rect_colors[62];
//         1 << 63: color = rect_colors[63];
//         default: color = DEFAULT_COLOR;
//     endcase
// end

endmodule
