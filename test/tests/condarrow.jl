using Base.Test
using Arrows
using Arrows.TestArrows




function test_cond_arrow()
  carr = TestArrows.cond_arr_eq()
  @test carr(4, 4) == (4,)
  @test carr(4, 7) == (7,)
end


test_cond_arrow()
