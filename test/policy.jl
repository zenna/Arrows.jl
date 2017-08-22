import Arrows
include("test_arrows.jl")

function test_policy()
  arr = det_policy_inner_arr()
  pol = Arrows.DetPolicy(arr)
end

a1 = all_test_arrows()[1]
Arrows.DetPolicy(a1)
