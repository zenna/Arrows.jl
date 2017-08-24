import Arrows
using Arrows.TestArrows

function test_policy()
  arr = TestArrows.xy_plus_x_arr()
  pol = Arrows.DetPolicy(arr)
end

arr = TestArrows.xy_plus_x_arr()
p = all_sub_ports(arr)[5]
sub_arrow(p)
test_policy()
