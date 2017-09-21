using Arrows
using Base.Test
using Arrows.TestArrows
using Base.Test


function test_src_value()
  x,y,z = sub_ports(TestArrows.xy_plus_x_arr())
  @test same(Arrows.SrcValue.(Arrows.out_neighbors(x)))
end

test_src_value()


#x,y,z = sub_ports(TestArrows.xy_plus_x_arr())
#sprtvals = (x => @NT(is_const = isconst, shape = (1,2,3)))
