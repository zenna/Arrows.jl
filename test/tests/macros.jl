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

function test_assignment()
  carr, f = Arrows.@arr function f(x, y)
    z = x + y
    z
  end
  @test carr(3, 4) == (7,)
  @test carr(3, 4) == (f(3, 4),)
end


function test_conditional1()
  carr, f = Arrows.@arr function f(x, y)
    if x > y
      2x + y
    else
      3x + y
    end
  end
  @test carr(3.0, 4.0) == (13.0,)
  @test carr(3, 4) == (f(3, 4),)
  @test carr(4, 3) == (11,)
  @test carr(4, 3) == (f(4, 3),)
end

function test_conditional_eq()
  carr, f = Arrows.@arr function f(x, y)
    if x == y
      2x + y
    else
      3x + y
    end
  end
  @test carr(4, 4) == (12,)
  @test carr(4, 4) == (f(4, 4),)
  @test carr(4, 3) == (15,)
  @test carr(4, 3) == (f(4, 3),)
end

test_operations()
test_assignment()
test_conditional1()
test_conditional_eq()
