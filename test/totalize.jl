using Arrows
using Base.Test
import Arrows: aprx_totalize

function test_aprx_errors()
  arr = SqrtArrow()
  arr_w_errors = aprx_errors(arr)
  total_arr = aprx_totalize(arr_w_errors)
  # total_arr(-2.0)
end


test_aprx_errors()

# function test_δinterval()
#   carr = CompArrow(:tcarr, [:x], [:y])
#   x, y = sub_ports(carr)
#   zz = δinterval(x, -1, 1)
#   zz ⥅ y
#   @test carr(0.5)[1] == 0
#   @test carr(-4)[1] > 0
# end
#
# test_δinterval()
