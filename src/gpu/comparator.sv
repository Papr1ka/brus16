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
    input   wire [COORD_WIDTH-1:0] left,    // rect_left || rect_top (unsigned)
    input   wire [COORD_WIDTH-1:0] right,   // rect_right || rect_bottom (unsigned)

    input   wire [COORD_WIDTH-1:0] coord,   // x || y
    output  logic collision
);

always_comb begin
    collision = (
        (left <= coord) &&
        (coord < right)
    );
end

endmodule
