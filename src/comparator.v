/*
    Comparator
    check's that point (coord_x, coord_y)
    collide with rect (rect_left, rect_top, rect_right, rect_bottom)

    async
*/

module comparator
#(
    parameter COORD_WIDTH = 16
)
(
    input wire[COORD_WIDTH-1:0] rect_left,
    input wire[COORD_WIDTH-1:0] rect_top,
    input wire[COORD_WIDTH-1:0] rect_right,
    input wire[COORD_WIDTH-1:0] rect_bottom,

    input wire[COORD_WIDTH-1:0] coord_x,
    input wire[COORD_WIDTH-1:0] coord_y,
    output reg collision
);

always @(*) begin
    collision = (
        (
            (rect_left <= coord_x) &&
            (coord_x < rect_right)
        ) &&
        (
            (rect_top <= coord_y) &&
            (coord_y < rect_bottom)
        )
    );
end

endmodule
