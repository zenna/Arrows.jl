using Arrows
using Base.Test
import Arrows: aprx_totalize

function test_aprx_totalize()
  carr = SqrArrow() >> ASinArrow()
  total_arr = aprx_totalize(carr)
  @test is_wired_ok(carr)
end

test_aprx_totalize()

function test_aprx_error()
  arr = SqrtArrow()
  arr_w_errors = aprx_error(arr)
  total_arr = aprx_totalize(arr_w_errors)
  @test total_arr(2.0)[2] == 0
  @test total_arr(-4.0)[2] > 0
end

test_aprx_error()

function test_has_error_ports()
  arr = TestArrows.xy_plus_x_arr()
  invarr = aprx_error(invert(arr))
  @test !isempty(invarr[isϵ])
end

test_has_error_ports()
