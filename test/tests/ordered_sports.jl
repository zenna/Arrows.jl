using Arrows
using Arrows.TestArrows
using Test



function test_ordered()
  carr = TestArrows.xy_plus_x_arr()
  s_star, s_plus = sub_arrows(carr)
  sport1 = ⬨(s_plus)[3]
  sport2 = ⬨(s_star)[3]
  z = ⬨(carr)[3]
  sports = [sport1, sport2, z]
  order = order_sports(carr, sports)
  @test sports[order] == [sport2, sport1, z]
end

function test_basic_order()
  carr = TestArrows.xy_plus_x_arr()
  sports = ⬨(carr)
  order = order_sports(carr, sports)
  @test sports[order] == sports
end

function test_invert_order()
  carr = TestArrows.xy_plus_x_arr()
  inv_carr =  invert(carr)
  sports = ⬨(inv_carr)
  x, y, z = sports[1:3]
  order = order_sports(inv_carr, sports)
  @test sports[order[1]] == z
  @test sports[order[end]] ∈ [x, y]
  @test sports[order[end-1]] ∈ [x, y]
end

test_ordered()
test_basic_order()
test_invert_order()
