using Base.Test
using Arrows
using Arrows.TestArrows
import Arrows: sub_arrows, add_sub_arr!, replace_sub_arr!, rem_sub_arr!

function test_rem_sub_arr()
  arr = sin_arr()
  sarrs = sub_arrows(arr)
  rem_sub_arr!(sarrs[1])
  @test !is_valid(arr)
  cosarr = add_sub_arr!(arr, CosArrow())
  x, y = ⬨(arr)
  a, b = ⬨(cosarr)
  x ⥅ a
  b ⥅ y
  @test is_valid(arr)
end

test_rem_sub_arr()

function test_replace_sub_arr()
  arr = sin_arr()
  sinarr = Arrows.sub_arrows(arr)[1]
  replace_sub_arr!(sinarr, CosArrow(), Dict(1=>1, 2=>2))
  @test is_valid(arr)
end

test_replace_sub_arr()

function test_compcall()
  f(x) = sin((x * x + x) / x)
  carr = CompArrow(:test, [:x], [:y])
  x, y = ⬨(carr)
  g(x) = f(f(f(f(x))))
  g(x)
  num_sub_arrows(carr)

  # Try instead with CompCall
  carr = CompArrow(:test, [:x], [:y])
  x, y = ⬨(carr)
  out, = compcall(f, compcall(f, (compcall(f, compcall(f, x)))))
  out ⥅ y
  @test is_valid(carr)
  @test all(sarr -> isa(deref(sarr), CompArrow), sub_arrows(carr))
  @test carr(3)[1] == g(3)
end

function test_inner_sub_ports(carr::CompArrow)
  sprts = inner_sub_ports(carr)
  for sarr in sub_arrows(carr)
    for sprt in ⬨(sarr)
      if sprt ∉ sprts
        @show deref(sprt)
        false
      end
    end
  end
  true
end

function badnested()
  carr = CompArrow(:inner, [:x], [:y])
  carr2 = CompArrow(:outer)
  add_sub_arr!(carr2, carr)
  foreach(Arrows.link_to_parent!, inner_sub_ports(carr2))
  @test is_wired_ok(carr2)
  @test !Arrows.is_wired_ok_recur(carr2)
end
