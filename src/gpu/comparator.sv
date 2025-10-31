/*
    Comparator
    check's that point (coord_x, coord_y)
    collide with rect (rect_left, rect_top, rect_right, rect_bottom)

    async
*/

`include "constants.svh"


module comparator
#(
    parameter COORD_WIDTH = `COORD_WIDTH
)
(
    input   wire [COORD_WIDTH-1:0] left,
    input   wire [COORD_WIDTH-1:0] right,
    input   wire                   equal,   // lte or lt
    output  logic                  collision
);

always_comb begin
    collision = equal ?
                    (left <= right) :
                    (left < right);
end

endmodule
