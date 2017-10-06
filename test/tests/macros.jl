using Arrows
using Base.Test
using Arrows.TestArrows
using Base.Test


function test_operations()
  carr, f = Arrows.@arr function f(x, y)
      2x + y
    end
  @test carr(3, 4) == f(3, 4)
end

test_operations()
