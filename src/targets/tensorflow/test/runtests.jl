using Arrows
using Arrows.TestArrows
using Base.Test
using Arrows.TensorFlowTarget

function pre_test(arr::Arrow)
  println("Testing arrow ", name(arr))
  arr
end

function test_to_graph(arr)
  Arrows.TensorFlowTarget.Graph(arr)
end

foreach(test_to_graph ∘ pre_test, plain_arrows())

function test_tf_optimize()
  carr = Arrows.TestArrows.xy_plus_x_arr()
  invcarr = aprx_invert(carr)
  ϵprt = ◂(invcarr, is(ϵ), 1)
  over = ▸(invcarr, is(θp))
  Arrows.TensorFlowTarget.optimize(invcarr, over, ϵprt, rand(length(▸(invcarr))), [], TFTarget)
end

test_tf_optimize()
