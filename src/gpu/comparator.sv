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
    input wire[COORD_WIDTH-1:0] rect_left,
    input wire[COORD_WIDTH-1:0] rect_top,
    input wire[COORD_WIDTH-1:0] rect_right,
    input wire[COORD_WIDTH-1:0] rect_bottom,

    input wire[COORD_WIDTH-1:0] coord_x,
    input wire[COORD_WIDTH-1:0] coord_y,
    output logic collision
);

always_comb begin
    collision = (
        (
            ($signed(rect_left) <= $signed(coord_x)) &&
            ($signed(coord_x) < $signed(rect_right))
        ) &&
        (
            ($signed(rect_top) <= $signed(coord_y)) &&
            ($signed(coord_y) < $signed(rect_bottom))
        )
    );
end

endmodule
