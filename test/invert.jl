using Arrows
using Arrows.TestArrows
using Base.Test

function pre_test(arr::Arrow)
  println("Testing arrow ", name(arr))
  arr
end

function test_invert(arr)
  duplify!(arr)
  inv_arr = invert(arr)
  @test is_wired_ok(inv_arr)
end

function test_aprx_invert(arr)
  duplify!(arr)
  inv_arr = aprx_invert(arr)
  @test is_wired_ok(inv_arr)
end

foreach(test_aprx_invert ∘ pre_test, plain_arrows())
foreach(test_invert ∘ pre_test, plain_arrows())
#
# xyx = TestArrows.xy_plus_x_arr()
# invxyx = invert(xyx)
# @assert is_wired_ok(invxyx)
#
# link_to_parent!(invxyx, loose ∧ is_dst)
#
# invxyx
#
# @which is_dst(sub_port_vtx(invxyx, 6))
#
