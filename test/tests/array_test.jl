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


test_scatter_nd_prim()
