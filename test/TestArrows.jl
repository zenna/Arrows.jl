"Various test (example) arrows and generators of test_arrows"
module TestArrows
using Arrows
import Arrows: add_sub_arr!, wrap

"f(x) = x^2"
function sin_arr()
  c = CompArrow{1, 1}(:x2)
  x, y = ports(c)
  sinarr = add_sub_arr!(c, SinArrow())
  link_ports!(c, x, in_port(sinarr, 1))
  link_ports!(c, out_port(sinarr, 1), y)
  c
end

"x * y + x"
function xy_plus_x_arr()
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

xy_plus_x_jl(x, y) = x * y + x

"f(x) = f(x)"
function recursive_arr()
  c = CompArrow{1, 1}(:recursive)
  c_wrap = add_sub_arr!(c, wrap(c))
  x, y = ports(c)
  x_wrap, y_wrap = ports(c_wrap)
  link_ports!(c, x, x_wrap)
  link_ports!(c, y_wrap, y)
  c
end

"arrow that computes nth value of fibonnaci sequence"
function fibonnaci_arr()
  c = CompArrow{1, 1}(:fib)
  c_wrap = add_sub_arr!(c, c)
  x, y = ports(c)
  one = add_sub_arr!(c, SourceArrow(1))
  min = add_sub_arr!(c, SubtractArrow())
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

fibonnaci_jl(x::Integer) = x == 1 ? 1 : x + fib(x - 1)

"f(x) = id(x), id(x)"
function dupl_id_arr()
  c = CompArrow{1, 2}(:dupl_id)
  id1 = add_sub_arr!(c, IdentityArrow())
  id2 = add_sub_arr!(c, IdentityArrow())
  x, y, z = ports(c)
  link_ports!(c, x, in_port(id1, 1))
  link_ports!(c, x, in_port(id2, 1))
  link_ports!(c, out_port(id1, 1), y)
  link_ports!(c, out_port(id2, 1), z)
  c
end

"f(x) = if p(x) then p(x), f(x)[1] else p(x), g(f(x)[2])"
function det_policy_inner_arr()
  c = CompArrow{1, 2}(:f)
  f = add_sub_arr!(c, dupl_id_arr())
  p = add_sub_arr!(c, IdentityArrow())
  g = add_sub_arr!(c, IdentityArrow())
  ite = add_sub_arr!(c, CondArrow())

  link_ports!(c, c, 1, p, 1)
  link_ports!(c, p, 1, c, 1)
  link_ports!(c, p, 1, ite, 1)
  link_ports!(c, c, 1, f, 1)
  link_ports!(c, f, 1, ite, 2)
  link_ports!(c, f, 2, g, 1)
  link_ports!(c, g, 1, ite, 3)
  link_ports!(c, ite, 1, c, 2)
  c
end

"f(x,y) = (x+y) + (x+y)"
function triple_add()
  c = CompArrow{2, 1}(:xyxy)
  x, y, z = ports(c)
  a1 = Arrows.add_sub_arr!(c, Arrows.AddArrow())
  a2 = Arrows.add_sub_arr!(c, Arrows.AddArrow())
  a3 = Arrows.add_sub_arr!(c, Arrows.AddArrow())
  link_ports!(c, c, 1, a1, 1)
  link_ports!(c, c, 1, a2, 1)
  link_ports!(c, c, 2, a1, 2)
  link_ports!(c, c, 2, a2, 2)
  link_ports!(c, a3, 1, c, 1)
  c
end

"all test arrows"
function all_test_arrows()
  [xy_plus_x_arr(),
   recursive_arr(),
   fibonnaci_arr(),
   dupl_id_arr(),
   det_policy_inner_arr()]
end

export xy_plus_x_arr,
       recursive_arr,
       fibonnaci_arr,
       dupl_id_arr,
       det_policy_inner_arr,
       sin_arr,
       all_test_arrows
end
