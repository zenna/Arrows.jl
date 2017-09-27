using Arrows
using Base.Test

function test_overload()
  carr = CompArrow(:tester, [:x, :y], [:z])
  x, y, z = sub_ports(carr)
  (2x * y + x) ⥅ z
  @test is_valid(carr)
end

test_overload()
