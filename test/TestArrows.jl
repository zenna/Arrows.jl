"Various test (example) arrows and generators of test_arrows"
module TestArrows
using Arrows
import Arrows: add_sub_arr!, in_sub_port, out_sub_port, inv_add, inv_mul

"f(x) = x^2"
function sin_arr()
  c = CompArrow(:x2, 1, 1)
  x, y = ports(c)
  sinarr = add_sub_arr!(c, Arrows.SinArrow())
  link_ports!(x, in_sub_port(sinarr, 1))
  link_ports!(out_sub_port(sinarr, 1), y)
  c
end

"x * y + x"
function xy_plus_x_arr()
  c = CompArrow(:xyx, 2, 1)
  x, y, z = ports(c)
  mularr = MulArrow()
  m2 = add_sub_arr!(c, mularr)
  link_ports!(x, in_sub_port(m2, 1))
  link_ports!(y, in_sub_port(m2, 2))
  add_arr = AddArrow()
  add_arr = add_sub_arr!(c, add_arr)
  link_ports!(out_sub_port(m2, 1), in_sub_port(add_arr, 1))
  link_ports!(x, in_sub_port(add_arr, 2))
  link_ports!(out_sub_port(add_arr, 1), z)
  c
end

xy_plus_x_jl(x, y) = x * y + x

function inv_xy_plus_x()
  carr = CompArrow(:inv_xy_plus_x, [:z, :θ], [:x, :y])
  z, θ, x, y = sub_ports(carr)
  invadd = add_sub_arr!(carr, inv_add())
  invmul = add_sub_arr!(carr, inv_mul())
  invdupl = add_sub_arr!(carr, InvDuplArrow(2))

  addz, addθ, addx, addy = sub_ports(invadd)
  mulz, mulθ, mulx, muly = sub_ports(invmul)
  sub_ports(invdupl)
  link_ports!(z, addz)
  link_ports!(addx, mulz)
  link_ports!(θ, addθ)
  link_ports!(addy, (invdupl, 1))
  link_ports!(mulx, y)
  link_ports!((invdupl, 1), x)
  link_ports!(muly, (invdupl, 2))
  link_ports!(θ, mulθ)
  carr
end

"arrow that computes nth value of fibonnaci sequence"
function fibonnaci_arr()
  c = CompArrow(:fib, 1, 1)
  c_wrap = add_sub_arr!(c, c)
  x, y = ports(c)
  one = add_sub_arr!(c, SourceArrow(1))
  min = add_sub_arr!(c, SubtractArrow())
  ite = add_sub_arr!(c, CondArrow())
  eq = add_sub_arr!(c, EqualArrow())
  add = add_sub_arr!(c, AddArrow())

  # if x == 1
  link_ports!(x, in_sub_port(eq, 1))
  link_ports!(out_sub_port(one, 1), in_sub_port(eq, 2))
  link_ports!(out_sub_port(eq, 1), in_sub_port(ite, 1))

  # return x
  link_ports!(out_sub_port(one, 1), in_sub_port(ite, 2))

  # f(x - 1)
  link_ports!(x, in_sub_port(min, 1))
  link_ports!(out_sub_port(one, 1), in_sub_port(min, 2))
  link_ports!(out_sub_port(min, 1), in_sub_port(c_wrap, 1))

  # x + f(x - 1)
  link_ports!(out_sub_port(c_wrap, 1), in_sub_port(add, 1))
  link_ports!(x, in_sub_port(add, 2))
  link_ports!(out_sub_port(add, 1), in_sub_port(ite, 3))
  link_ports!(out_sub_port(ite, 1), y)
  c
end

fibonnaci_jl(x::Integer) = x == 1 ? 1 : x + fib(x - 1)

"f(x) = id(x), id(x)"
function dupl_id_arr()
  c = CompArrow(:dupl_id, 1, 2)
  id1 = add_sub_arr!(c, IdentityArrow())
  id2 = add_sub_arr!(c, IdentityArrow())
  x, y, z = ports(c)
  link_ports!(x, in_sub_port(id1, 1))
  link_ports!(x, in_sub_port(id2, 1))
  link_ports!(out_sub_port(id1, 1), y)
  link_ports!(out_sub_port(id2, 1), z)
  c
end

"f(x) = if p(x) then p(x), f(x)[1] else p(x), g(f(x)[2])"
function det_policy_inner_arr()
  c = CompArrow(:f, 1, 2)
  f = add_sub_arr!(c, dupl_id_arr())
  p = add_sub_arr!(c, IdentityArrow())
  g = add_sub_arr!(c, IdentityArrow())
  ite = add_sub_arr!(c, CondArrow())

  link_ports!((c, 1), (p, 1))
  link_ports!((p, 1), (c, 1))
  link_ports!((p, 1), (ite, 1))
  link_ports!((c, 1), (f, 1))
  link_ports!((f, 1), (ite, 2))
  link_ports!((f, 2), (g, 1))
  link_ports!((g, 1), (ite, 3))
  link_ports!((ite, 1), (c, 2))
  c
end

"f(x,y) = (x+y) + (x+y)"
function triple_add()
  c = CompArrow(:xyxy, 2, 1)
  x, y, z = ports(c)
  a1 = Arrows.add_sub_arr!(c, Arrows.AddArrow())
  a2 = Arrows.add_sub_arr!(c, Arrows.AddArrow())
  a3 = Arrows.add_sub_arr!(c, Arrows.AddArrow())
  link_ports!((c, 1), (a1, 1))
  link_ports!((c, 1), (a2, 1))
  link_ports!((c, 2), (a1, 2))
  link_ports!((c, 2), (a2, 2))
  link_ports!((a1, 1), (a3, 1))
  link_ports!((a2, 1), (a3, 2))
  link_ports!((a3, 1), (c, 1))
  c
end

"all test arrows"
function all_test_arrows()
  [xy_plus_x_arr(),
   fibonnaci_arr(),
   dupl_id_arr(),
   det_policy_inner_arr(),
   triple_add()]
end

function is_plain(arr::CompArrow)
  CondArrow() ∉ values(arr.sarr_name_to_arrow)
end

"Test Arrows without recursion or control flow"
function plain_arrows()
  collect(filter(is_plain, all_test_arrows()))
end

export xy_plus_x_arr,
       recursive_arr,
       fibonnaci_arr,
       dupl_id_arr,
       det_policy_inner_arr,
       sin_arr,
       all_test_arrows,
       plain_arrows
end
