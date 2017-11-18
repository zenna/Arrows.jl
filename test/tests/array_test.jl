using Arrows
using Base.Test
using Arrows.TestArrows
using Base.Test


function test_gather_nd()
  indices = [[1, 4] [2, 2]]
  params = reshape(collect(1:100), (10,10));
  shape = size(params)
  function f(params)
    return gather_nd(params, indices, shape)
  end
  c = CompArrow(:c, [:x], [:z])
  x, = ▹(c)
  f(x) ⥅ ◃(c,1)
  c = Arrows.duplify!(c)
  z = c(params,)
  inv_c = Arrows.invert(c)
  θ = zeros(10, 10) + 1
  inverted = inv_c(z, θ)
  @test sum(inverted) == (sum(θ) + sum(z))
end



test_gather_nd()
