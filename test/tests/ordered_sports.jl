using Arrows
using Arrows.TestArrows
using Base.Test



function test_ordered()
  carr = TestArrows.xy_plus_x_arr()
  s_star, s_plus = sub_arrows(carr)
  sport1 = sub_ports(s_plus)[3]
  sport2 = sub_ports(s_star)[3]
  z = sub_ports(carr)
  sports = [sport1, sport2, z]
  order = order_sports(carr, sports)
  @test sports[order] == [sport2, sport1, z]
end

test_propagate()
