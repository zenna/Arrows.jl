using Arrows
using Test
using Arrows.TestArrows


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

function test_inv_dupl_arr()
  c = CompArrow(:c, [:x, :y], [:z])
  s = add_sub_arr!(c, InvDuplArrow{2}())
  (c, 1) ⥅ (s, 1)
  (c, 2) ⥅ (s, 2)
  (s, 1) ⥅ (c, 1)
  @test c(1:2, 1:2) == collect(1:2)
end

function test_mean_array()
  c = CompArrow(:c, [:x, :y], [:z])
  s = add_sub_arr!(c, MeanArrow{2}())
  (c, 1) ⥅ (s, 1)
  (c, 2) ⥅ (s, 2)
  (s, 1) ⥅ (c, 1)
  @test c([1, 2], [4,5]) == [2.5, 3.5]
end

test_gather_nd()
test_inv_dupl_arr()
test_mean_array()
