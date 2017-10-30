using Arrows
using Arrows.TestArrows
using Base.Test

function pre_test(arr::Arrow)
  println("Testing arrow ", name(arr))
  arr
end


function test_to_graph(arr)
  @show arr
  g = Arrows.TensorFlowTarget.Graph(arr)
end

foreach(test_to_graph ∘ pre_test, plain_arrows())
