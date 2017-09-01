using Arrows
import Arrows.TestArrows

using Arrows.TestArrows

arr = Arrows.TestArrows.xy_plus_x_arr()
duplify!(arr)
no_reuse(arr)
inv_arr = Arrows.invert(arr)

inv(DuplArrow(3))

@assert false, "hello"

port
