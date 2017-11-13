using Arrows
using Arrows.TestArrows
using Base.Test

function pre_test(arr::Arrow)
  println("Testing supervised ", name(arr))
  arr
end

function test_foreign_arr(arr = TestArrows.xy_plus_x_arr())
  invarr = aprx_invert(arr)
  pslarr = Arrows.psl(invarr)
  @show invarr
  @show pslarr
  pslarr = invarr
  superarr = Arrows.supervised(arr, pslarr)
  suploss = Arrows.supervisedloss(superarr)
end

foreach(test_foreign_arr ∘ pre_test, plain_arrows())
