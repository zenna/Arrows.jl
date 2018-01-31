using Arrows
using Arrows.TestArrows
using Base.Test

function pre_test(arr::Arrow)
  println("Testing arrow ", name(arr))
  arr
end

function test_pgf(arr)
  randin = rand(length(▸(arr)))
  basic_test_pgf(arr, randin)
end

function basic_test_pgf(arr, input)
  pgfarr = pgf(arr)
  pgfout = pgfarr(input...)
  invarr = invert(arr)
  out = invarr(pgfout...)
  @test all(map(≈, input, out))
end

test_pgf(Arrows.TestArrows.xy_plus_x_arr())

foreach(test_pgf ∘ pre_test, plain_arrows())


function test_greaterthan_pgf()
  carr = CompArrow(:test_gt_pgf, [:x], [:z])
  x, z = ⬨(carr)
  x > 3 ⥅ z
  basic_test_pgf(carr, (4,))
  basic_test_pgf(carr, (2,))
  carr = CompArrow(:test_gt_pgf, [:x], [:z])
  x, z = ⬨(carr)
  3 > x ⥅ z
  basic_test_pgf(carr, (4,))
  basic_test_pgf(carr, (2,))
  carr = CompArrow(:test_gt_pgf, [:x, :y], [:z])
  x, y, z = ⬨(carr)
  x > y ⥅ z
  basic_test_pgf(carr, (4,3))
  basic_test_pgf(carr, (3,4))
end

test_greaterthan_pgf()