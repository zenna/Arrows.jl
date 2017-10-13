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


function test_aprx_inverse()
  fwdarr = TestArrows.xy_plus_x_arr()
  invarr = Arrows.aprx_invert(fwdarr)
  @test is_valid(fwdarr)
end

function test_id_loss()
  sin_arr = Arrows.TestArrows.sin_arr()
  aprx = Arrows.aprx_invert(sin_arr)
  lossarr = Arrows.id_loss(sin_arr, aprx)
  @test is_valid(lossarr)
end

test_inv_xy_plus_x()
test_aprx_inverse()
test_id_loss()
