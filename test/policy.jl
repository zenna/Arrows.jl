import Arrows
using Arrows.TestArrows

function test_policy()
  arr = TestArrows.xy_plus_x_arr()
  pol = Arrows.DetPolicy(arr)
end

pol = test_policy()
is_valid(pol)
interpret(pol, 10, 20)
collect(LG.edges(pol.edges))
# - Might want to interpret with Symbol, in Julia, in San
# -
