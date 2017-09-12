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

function test_replace_sub_arr()
  arr = sin_arr()
  sinarr = Arrows.sub_arrows(arr)[1]
  replace_sub_arr!(sinarr, CosArrow(), Dict(1=>1, 2=>2))
  @test is_wired_ok(arr)
end

test_rem_sub_arr()
test_replace_sub_arr()
