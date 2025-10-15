/*
    1*READ 1*WRITE sync memory
    intended to be implemented as block ram
    sync read, sync write
*/

module bsram
#(
    parameter WIDTH = 13,
    parameter SIZE = 8192,
    parameter LOAD_PROGRAM = 1
)
(
    input wire clk,

    // read
    input wire [WIDTH-1:0] mem_dout_addr,
    output reg [15:0] mem_dout,
    
    // write
    input wire we,
    input wire [WIDTH-1:0] mem_din_addr,
    input wire [15:0] mem_din
);

reg [15:0] data [SIZE-1:0];

always_ff @(posedge clk) begin
    if (we) begin
        data[mem_din_addr] <= mem_din;
    end
    mem_dout <= data[mem_dout_addr];
end

initial begin
    for (integer i = 0; i < SIZE; i = i + 1) begin
        data[i] = 16'b0;
    end
    if (LOAD_PROGRAM) begin
        // game program
        	data[0] = 65136;
	data[1] = 19456;
	data[2] = 23041;
	data[3] = 40967;
	data[4] = 49160;
	data[5] = 25600;
	data[6] = 32770;
	data[7] = 22016;
	data[8] = 18947;
	data[9] = 65152;
	data[10] = 17920;
	data[11] = 23040;
	data[12] = 17921;
	data[13] = 16897;
	data[14] = 23552;
	data[15] = 11784;
	data[16] = 41026;
	data[17] = 23040;
	data[18] = 17922;
	data[19] = 16898;
	data[20] = 23552;
	data[21] = 11784;
	data[22] = 41021;
	data[23] = 16898;
	data[24] = 23552;
	data[25] = 2640;
	data[26] = 16896;
	data[27] = 23552;
	data[28] = 513;
	data[29] = 17408;
	data[30] = 16897;
	data[31] = 23552;
	data[32] = 2620;
	data[33] = 16896;
	data[34] = 23552;
	data[35] = 514;
	data[36] = 17408;
	data[37] = 23120;
	data[38] = 16896;
	data[39] = 23552;
	data[40] = 515;
	data[41] = 17408;
	data[42] = 23100;
	data[43] = 16896;
	data[44] = 23552;
	data[45] = 516;
	data[46] = 17408;
	data[47] = 49238;
	data[48] = 16896;
	data[49] = 23552;
	data[50] = 517;
	data[51] = 17408;
	data[52] = 16896;
	data[53] = 23552;
	data[54] = 518;
	data[55] = 17920;
	data[56] = 16898;
	data[57] = 23552;
	data[58] = 513;
	data[59] = 17922;
	data[60] = 32787;
	data[61] = 16897;
	data[62] = 23552;
	data[63] = 513;
	data[64] = 17921;
	data[65] = 32781;
	data[66] = 23050;
	data[67] = 49221;
	data[68] = 22019;
	data[69] = 18946;
	data[70] = 17920;
	data[71] = 23040;
	data[72] = 17921;
	data[73] = 16897;
	data[74] = 23552;
	data[75] = 16896;
	data[76] = 23552;
	data[77] = 11264;
	data[78] = 41045;
	data[79] = 25600;
	data[80] = 16897;
	data[81] = 23552;
	data[82] = 513;
	data[83] = 17921;
	data[84] = 32841;
	data[85] = 22018;
	data[86] = 57344;
	data[87] = 16384;
	data[88] = 23552;
	data[89] = 57344;
	data[90] = 16384;
	data[91] = 23552;
	data[92] = 6663;
	data[93] = 5120;
	data[94] = 57344;
	data[95] = 17408;
	data[96] = 57344;
	data[97] = 16384;
	data[98] = 23552;
	data[99] = 57344;
	data[100] = 16384;
	data[101] = 23552;
	data[102] = 23049;
	data[103] = 8192;
	data[104] = 5120;
	data[105] = 57344;
	data[106] = 17408;
	data[107] = 57344;
	data[108] = 16384;
	data[109] = 23552;
	data[110] = 57344;
	data[111] = 16384;
	data[112] = 23552;
	data[113] = 6664;
	data[114] = 5120;
	data[115] = 57344;
	data[116] = 17408;
	data[117] = 57344;
	data[118] = 16384;
	data[119] = 23552;
	data[120] = 22016;

    end else begin
        // game data
        data[0] = 1;
    end
end


endmodule
