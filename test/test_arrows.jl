using Arrows
import Arrows: is_wired_ok
using Base.Test

"x * y + x"
function xy_plus_x()
  c = CompArrow{2, 1}(:xyx)
  x, y, z = ports(c)
  mularr = MulArrow()
  m2 = add_sub_arr!(c, mularr)
  link_ports!(c, x, in_port(m2, 1))
  link_ports!(c, y, in_port(m2, 2))
  add_arr = AddArrow()
  add_arr = add_sub_arr!(c, add_arr)
  link_ports!(c, out_port(m2, 1), in_port(add_arr, 1))
  link_ports!(c, x, in_port(add_arr, 2))
  link_ports!(c, out_port(add_arr, 1), z)
  c
end

arr = xy_plus_x()
@test is_wired_ok(arr)
@test is_wired_ok(wrap(arr))

# function xy_plus_x_port_arith()
#   c = CompArrow{2, 1}(:xyx)
#   x, y, z = ports(c)
#   add_out_port = x * y + x
#   link_ports!(c, add_out_port, z)
#   c
# end
#
# @test is_wired_ok(xy_plus_x_port_arith())

"f(x) = f(x)"
function recursive_test()
  c = CompArrow{1, 1}(:recursive)
  c_wrap = add_sub_arr!(c, wrap(c))
  x, y = ports(c)
  x_wrap, y_wrap = ports(c_wrap)
  link_ports!(c, x, x_wrap)
  link_ports!(c, y_wrap, y)
  c
end

arr = recursive_test()
@test is_wired_ok(arr)

"arrow that computes nth value of fibonnaci sequence"
function fibonnaci()
  c = CompArrow{1, 1}(:fib)
  c_wrap = add_sub_arr!(c, wrap(c))
  x, y = ports(c)
  one = add_sub_arr!(c, SourceArrow(1))
  min = add_sub_arr!(c, SubArrow())
  ite = add_sub_arr!(c, CondArrow())
  eq = add_sub_arr!(c, EqualArrow())
  add = add_sub_arr!(c, AddArrow())

  # if x == 1
  link_ports!(c, x, in_port(eq, 1))
  link_ports!(c, out_port(one, 1), in_port(eq, 2))
  link_ports!(c, out_port(eq, 1), in_port(ite, 1))

  # return x
  link_ports!(c, out_port(one, 1), in_port(ite, 2))

  # f(x - 1)
  link_ports!(c, x, in_port(min, 1))
  link_ports!(c, out_port(one, 1), in_port(min, 2))
  link_ports!(c, out_port(min, 1), in_port(c_wrap, 1))

  # x + f(x - 1)
  link_ports!(c, out_port(c_wrap, 1), in_port(add, 1))
  link_ports!(c, x, in_port(add, 2))
  link_ports!(c, out_port(add, 1), in_port(ite, 3))
  link_ports!(c, out_port(ite, 1), y)
  c
end

f = fibonnaci()
@test is_wired_ok(f)
