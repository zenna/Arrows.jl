using Arrows
using Base.Test
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
  @test is_wired_ok(fwdarr)
end

test_aprx_inverse()
