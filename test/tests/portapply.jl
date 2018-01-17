using Base.Test
using Arrows

function test_port_apply()
  carr = CompArrow(:test, [:x, :y], Symbol[])
  x, y = ▹(carr)
  (z,) = TestArrows.xy_plus_x_arr()(x, y)
  ret = DivArrow()(z, 5)
  Arrows.link_to_parent!(ret)
  carr
  @assert is_valid(carr)
end
