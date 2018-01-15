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
  @test is_valid(inv_arr)
end

function test_aprx_invert(arr)
  duplify!(arr)
  inv_arr = aprx_invert(arr)
  @test is_valid(inv_arr)
end

foreach(test_aprx_invert ∘ pre_test, plain_arrows())
foreach(test_invert ∘ pre_test, plain_arrows())

function test_ex_invert()
  arr = TestArrows.xy_plus_x_arr()
  invarr = invert(arr)
  aprxarr = domain_error!(invarr)
  @test is_valid(aprxarr)
end

test_ex_invert()


function test_xor_invert()
  xor = Arrows.wrap(XorArrow())
  inv_x = invert(xor)
  left, right = 0x19, 0xf3
  @test inv_x(xor(left, right), left) == (right, left)
end

test_xor_invert()
