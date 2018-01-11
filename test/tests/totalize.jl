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


function test_apprx_div_propagate()
  c = CompArrow(:c, [:x, :y], [:z])
  x, y, z = ⬨(c)
  (x/y) ⥅ z
  apprx = aprx_totalize!(c)
  sz = Size([3,2])
  abtvals = Arrows.traceprop!(apprx, Dict(x => AbValues(:size => sz),
                                         y => AbValues(:size => sz)))
  @test Arrows.if_symbol_on_sport(abtvals, :size, z,
                    (x)->x == sz,
                    ()->false)
end

test_apprx_div_propagate()


function test_apprx_log_propagate()
  c = CompArrow(:c, [:x], [:z])
  x, z = ⬨(c)
  log(x) ⥅ z
  apprx = aprx_totalize!(c)
  @test all(exp.(apprx([0, 0.1])) .> 0)
  sz = Size([3,2])
  abtvals = Arrows.traceprop!(apprx, Dict(x => AbValues(:size => sz)))
  @test Arrows.if_symbol_on_sport(abtvals, :size, z,
                    (z)->z == sz,
                    ()->false)
end

test_apprx_log_propagate()
