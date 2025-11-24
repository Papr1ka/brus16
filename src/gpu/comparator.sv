/*
    Async comparator for two values
*/

`include "constants.svh"


module comparator
#(
    parameter COORD_WIDTH = `COORD_WIDTH
)
(
    input   wire [COORD_WIDTH-1:0] left,
    input   wire [COORD_WIDTH-1:0] right,
    input   wire                   equal,    // lte or lt
    output  logic                  collision
);

assign collision = equal ? (left <= right) : (left < right);

endmodule
