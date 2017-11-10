using Arrows
using Arrows.TestArrows
import Arrows: floss
using Base.Test

function pre_test(arr::Arrow)
  println("Testing arrow ", name(arr))
  arr
end

function test_exact_inverse()
  fwdarr = TestArrows.xy_plus_x_arr()
  invarr = TestArrows.inv_xy_plus_x_arr()
  lossarr = Arrows.id_loss(fwdarr, invarr)
  @test lossarr(1.0, 2.0) == 0
end

test_exact_inverse()

function test_floss(arr::Arrow)
  invarr = aprx_invert(arr) # dont totalize
  sumxs(ys, xs) = sum(xs)
  floss(invarr, sumxs)
end

foreach(test_floss ∘ pre_test, plain_arrows())
