import Arrows
using Arrows.TestArrows

function test_policy()
  arr = TestArrows.xy_plus_x_arr()
  pol = Arrows.DetPolicy(arr)
end

pol = test_policy()
interpret(pol, 10, 2)

DetPolicy()


LG.outdegree
