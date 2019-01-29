using Arrows
using Test

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

test_pgf(TestArrows.xy_plus_x_arr())

"Are Pgf and Pi consistent - `invf(f(x); pgf(x) = x`"
function ispipgfid(f::Arrow, x::Vector, xabv::XAbVals=NmAbVals(), eq=(==))
  invf = invert(f, inv, xabv) 
  pgff = pgf(f, pgf, xabv)
  y, θ = (AlioAnalysis.y_θ_split(pgff) ∘ pgff)(x...)
  x = invf(y..., θ...)
  all(map(eq, x, x))
end


foreach(test_pgf ∘ pre_test, plain_arrows())
