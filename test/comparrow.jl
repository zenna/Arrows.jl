using Base.Test
using Arrows
using Arrows.TestArrows
import Arrows: sub_arrows, add_sub_arr!, replace_sub_arr!, rem_sub_arr!

function test_rem_sub_arr()
  arr = sin_arr()
  sarrs = sub_arrows(arr)
  rem_sub_arr!(sarrs[1])
  @test !is_wired_ok(arr)
  cosarr = add_sub_arr!(arr, CosArrow())
  x, y = sub_ports(arr)
  a, b = sub_ports(cosarr)
  link_ports!(x, a)
  link_ports!(b, y)
  @test is_wired_ok(arr)
end

test_rem_sub_arr()

function test_replace_sub_arr()
  arr = sin_arr()
  sinarr = Arrows.sub_arrows(arr)[1]
  replace_sub_arr!(sinarr, CosArrow(), Dict(1=>1, 2=>2))
  @test is_wired_ok(arr)
end

test_replace_sub_arr()

function test_compcall()
  f(x) = sin((x * x + x) / x)
  carr = CompArrow(:test, [:x], [:y])
  x, y = sub_ports(carr)
  g(x) = f(f(f(f(x))))
  g(x)
  num_sub_arrows(carr)

  # Try instead with CompCall
  carr = CompArrow(:test, [:x], [:y])
  x, y = sub_ports(carr)
  out, = compcall(f, compcall(f, (compcall(f, compcall(f, x)))))
  out ⥅ y
  @test is_wired_ok(carr)
  @test all(sarr -> isa(deref(sarr), CompArrow), sub_arrows(carr))
  @test carr(3)[1] == g(3)
end
