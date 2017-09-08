using Arrows
import Arrows.TestArrows
using Base.Test

function test_exact_inverse()
  fwdarr = TestArrows.xy_plus_x_arr()
  invarr = TestArrows.inv_xy_plus_x_arr()
  iden_loss!(fwdarr, invarr)
end

arr = test_exact_inverse()
fwdarr = TestArrows.xy_plus_x_arr()
(invarr >> fwdarr)(1.0, 4.0)


invarr = TestArrows.inv_xy_plus_x_arr()
