using Base.Test
using Arrows
import Arrows: compose
import Arrows: TestArrows

function test_compose()
  arr1 = TestArrows.xy_plus_x_arr()
  sinarr = SinArrow()
  c = compose(sinarr, arr1)
  @test is_valid(c)
end

test_compose()
