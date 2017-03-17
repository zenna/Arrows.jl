using Arrows
import Arrows: is_wired_correct, CompArrow, AddArrow, link_ports
using Base.Test

"x * y + x"
function xy_plus_x()
  c = CompArrow{2, 1}(:xyx)
  x, y, z = ports(c)
  mularr = AddArrow()
  m2 = add_sub_arr!(mularr, c)
  link_ports!(c, x, in_port(m2, 1))
  link_ports!(c, y, in_port(m2, 2))
  add_arr = AddArrow()
  add_arr = add_sub_arr!(add_arr, c)
  link_ports!(c, out_port(m2, 1), in_port(add_arr, 1))
  link_ports!(c, x, in_port(add_arr, 2))
  link_ports!(c, out_port(add_arr, 1), z)
  c
end

@test is_wired_correct(xy_plus_x())
