using Base.Test
include("test_arrows.jl")

function test_xy_plus_x()
  arr = xy_plus_x_arr()
  @test is_wired_ok(arr)
  @test interpret(arr, 7, 8)[1] == xy_plus_x_jl(7, 8)
  duplify!(arr)
  @test is_wired_ok(arr)
end

function test_recursive()
  arr = recursive_arr()
  @test is_wired_ok(arr)
end

function test_fibonnaci()
  f = fibonnaci_arr()
  @test interpret(f, 4)[1] == fib(4)
  @test is_wired_ok(f)
end

test_xy_plus_x()
test_recursive()
