using Arrows
using Base.Test

function test_inv_xy_plus_x()
  z_orig  = rand()
  θ = rand()
  x, y = TestArrows.inv_xy_plus_x_arr()(z_orig, θ)
  z_new = x * y + x
  @test z_new ≈ z_orig
end

test_inv_xy_plus_x()

function test_approx_inverse()
  fwdarr = TestArrows.xy_plus_x_arr()
  invarr = invert(fwdarr)
  approx_totalize!(invarr)
  lossarr = Arrows.iden_loss(fwdarr, invarr)
  @test lossarr(1.0, 2.0, 1.0)[1] == 0
end

test_approx_inverse()



fwdarr = TestArrows.xy_plus_x_arr()
invarr = invert(fwdarr)
lossarr = Arrows.iden_loss(fwdarr, invarr)
lossarr(1.0, 1.0, 1.0)
