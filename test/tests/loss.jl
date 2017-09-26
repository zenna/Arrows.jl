using Arrows
import Arrows.TestArrows
using Base.Test

function test_exact_inverse()
  fwdarr = TestArrows.xy_plus_x_arr()
  invarr = TestArrows.inv_xy_plus_x_arr()
  lossarr = Arrows.id_loss(fwdarr, invarr)
  @test lossarr(1.0, 2.0)[1] == 0
end

test_exact_inverse()
