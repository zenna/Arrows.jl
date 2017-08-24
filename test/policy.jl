import Arrows
using Arrows.TestArrows

function test_policy()
  arr = xy_plus_x_arr()
  pol = Arrows.DetPolicy(arr)
end

test_policy()
