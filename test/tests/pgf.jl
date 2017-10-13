using Arrows
using Arrows.TestArrows
using Base.Test

function pre_test(arr::Arrow)
  println("Testing arrow ", name(arr))
  arr
end

function test_pgf(arr)
  randin = rand(length(▸(arr)))
  pgfarr = pgf(arr)
  pgfout = pgfarr(randin...)
  invarr = invert(arr)
  out = invarr(pgfout...)
  @test all(map(≈, randin, out))
end

test_pgf(Arrows.TestArrows.xy_plus_x_arr())

# foreach(test_pgf ∘ pre_test, plain_arrows())
