using Arrows
using Base.Test
import Arrows: aprx_totalize

function test_aprx_totalize()
  carr = SqrArrow() >> ASinArrow()
  total_arr = aprx_totalize(carr)
  @test is_wired_ok(carr)
end

test_aprx_totalize()

function test_aprx_errors()
  arr = SqrtArrow()
  arr_w_errors = aprx_errors(arr)
  total_arr = aprx_totalize(arr_w_errors)
  @test total_arr(2.0)[2] == 0
  @test total_arr(-4.0)[2] > 0
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
