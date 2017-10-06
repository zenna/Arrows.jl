using Arrows
using Base.Test
using Arrows.TestArrows
using Base.Test


function test_operations()
  carr, f = Arrows.@arr function f(x, y)
      2x + y
    end
  @test carr(3, 4) == (f(3, 4),)
end

function test_assigment()
  carr, f = Arrows.@arr function f(x, y)
    z = x + y
    z
  end
  @test carr(3, 4) == (7,)
  @test carr(3, 4) == (f(3, 4))
end


function test_conditional()
  carr, f = Arrows.@arr function f(x, y)
    if x > y
      z = 2x + y
    else
      z = 3x + y
    end
    z
  end
  @test carr(3, 4) == (13,)
  @test carr(3, 4) == (f(3, 4))
  @test carr(3, 4) == (15,)
  @test carr(4, 3) == (f(4, 3))
end

test_operations()
test_assigment()
test_conditional()
