using Arrows
using Base.Test
import Arrows: aprx_totalize

function test_aprx_totalize()
  carr = SqrArrow() >> ASinArrow()
  total_arr = aprx_totalize(carr)
  @test is_valid(carr)
end

test_aprx_totalize()

function test_domain_error()
  arr = SqrtArrow()
  arr_w_errors = domain_error(arr)
  total_arr = aprx_totalize(arr_w_errors)
  @test total_arr(2.0)[2] == 0
  @test total_arr(-4.0)[2] > 0
end

test_domain_error()

function test_has_error_ports()
  arr = TestArrows.xy_plus_x_arr()
  invarr = domain_error(invert(arr))
  @test !isempty(⬧(invarr, is(ϵ)))
end

test_has_error_ports()

function test_apprx_div()
  c = CompArrow(:c, [:x, :y], [:z])
  x, y, z = ⬨(c)
  (x/y) ⥅ z
  apprx = aprx_totalize!(c)
  @test abs(apprx(-2, -4)) != Inf
  @test abs(apprx(132, 0)) != Inf
  @test abs(apprx(0, 0)) == 0
end

test_apprx_div()
