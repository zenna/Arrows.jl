using Arrows
using Test
using Arrows.TestArrows

function test_inv_xy_plus_x()
  z_orig  = rand()
  θ = rand()
  x, y = TestArrows.inv_xy_plus_x_arr()(z_orig, θ)
  z_new = x * y + x
  @test z_new ≈ z_orig
end

test_inv_xy_plus_x()

function test_aprx_inverse()
  fwdarr = TestArrows.xy_plus_x_arr()
  invarr = Arrows.aprx_invert(fwdarr)
  @test is_valid(fwdarr)
end
test_aprx_inverse()

function test_accumapply()
  f(x::Real) = [Real]
  f(x::Float64) = [Float64]
  f(x::Union{AbstractFloat, Int32}) = [AbstractFloat, Int32]
  Test.@test Set(vcat(accumapply(f, 3.0)...)) == Set([Real, Float64, AbstractFloat, Int32])
end

test_accumapply()
