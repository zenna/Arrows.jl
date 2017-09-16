using Arrows
using NamedTuples
using Arrows.TestArrows
using Base.Test


function test_propagate()
  carr = TestArrows.xy_plus_x_arr()
  x, y, z = sub_ports(carr)
  # Suppose we know the output has shape (1,2,3)
  sprtvals = Dict(z => @NT(:shape = Shape((1,2,3))))
  propagate!(carr, sprtvals)
  @test sprtvals[x].shape == Shape((1, 2, 3))
  @test sprtvals[y].shape == Shape((1, 2, 3))
end

test_propagate()
