using Arrows
using Arrows.TestArrows
using Base.Test

function pre_test(arr)
    println("Testing arrow ", name(arr))
    arr
end

function test_pgf(arr)
    pgf_arr = pgf(arr)
    @test is_wired_ok(pgf_arr)
end

foreach(test_pgf ∘ pre_test, plain_arrows())

function test_numerical_pgf(x::Float64, y::Float64)
    arr = TestArrows.xy_plus_x_arr()
    println("Testing pgf on x*y+x with inputs x=$x, y=$y.")
    z = arr(x, y)
    println("The output of the arrow is z=$z.")
    inv_arr = invert(arr)
    pgf_arr = pgf(arr)
    pgf_z, pgf_θ1, pgf_θ2 = pgf_arr(x, y)
    println("The output of the pgf is z=$pgf_z, θ1=$pgf_θ1, θ2=$pgf_θ2.")
    inv_x, inv_y = inv_arr(pgf_z, pgf_θ1, pgf_θ2)
    ϵ = 1e-10
    @test assert(abs(z-pgf_z)<ϵ && abs(x-inv_x)<ϵ && abs(y-inv_y)<ϵ)
end

test_numerical_pgf(1, 2)
