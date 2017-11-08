using Arrows
using Base.Test
using Arrows.TestArrows
using Base.Test



function test_scatter_nd_prim()
  indices = [[1, 4] [2, 2]]
  params = reshape(collect(1:100), (10,10))
  n = length(params)
  tofill = collect(1:5:1000)
  gathered =  Arrows.gather_nd(params, indices, size(params))
  inverted = Arrows.scatter_nd(gathered, indices, size(params), tofill)
  @test sum(inverted) == (sum(tofill[1:n-2]) + sum(gathered))
end

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
  inv_c = Arrows.invert(c)
  z = c(params,)
  θ = collect(1:5:1000);
  inverted = inv_c(z, θ)
  n = length(params)
  @test sum(inverted) == (sum(θ[1:n-2]) + sum(z))
end



test_scatter_nd_prim()
test_gather_nd()
