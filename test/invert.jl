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

foreach(test_invert ∘ pre_test, plain_arrows())
