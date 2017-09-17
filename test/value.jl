using Arrows
using Base.Test
function test_src_value()
  x,y,z = sub_ports(TestArrows.xy_plus_x_arr())
  @test same(SrcValue.(Arrows.out_neighbors(x)))
end

test_src_value()
