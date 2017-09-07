using Arrows
using Base.Test

function test_inv_xy_plus_x()
  z_orig  = rand()
  θ = rand()
  pols = Arrows.policies(TestArrows.inv_xy_plus_x())
  invarr = map(eval, Arrows.pol_to_julia.(pols))
  x, y = inv_xy_plus_x(z_orig, θ)
  z_new = x * y + x
  @test z_new ≈ z_orig
end

test_inv_xy_plus_x()
