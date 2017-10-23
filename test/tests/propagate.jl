using Arrows
using NamedTuples
using Arrows.TestArrows
using Base.Test


function test_propagate()
  carr = TestArrows.xy_plus_x_arr()
  x, y, z = ⬨(carr)
  # Suppose we know the output has shape (1,2,3)
  shapes = Dict(z => Shape((1,2,3)))
  propagate!(carr, shapes)
  @test shapes[x] == Shape((1, 2, 3))
  @test shapes[y] == Shape((1, 2, 3))
end

test_propagate()
