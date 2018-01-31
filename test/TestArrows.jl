"Various test (example) arrows and generators of test_arrows"
module TestArrows
using Arrows
import Arrows: add_sub_arr!, in_sub_port, out_sub_port, inv_add, inv_mul, bsource!

"f(x) = sin(x)"
function sin_arr(bcast=identity)
  c = CompArrow(:x2, 1, 1)
  x, y = ⬧(c)
  sinarr = add_sub_arr!(c, Arrows.SinArrow())
  x ⥅ (sinarr, 1)
  (sinarr, 1) ⥅ y
  c
end

"x * y + x"
function xy_plus_x_arr(bcast=identity)
  c = CompArrow(:xyx, [:x, :y], [:z])
  x, y, z = ⬧(c)
  m2 = add_sub_arr!(c, MulArrow())
  add_arr = add_sub_arr!(c, AddArrow())
  x ⥅ (m2, 1)
  y ⥅ (m2, 2)
  (m2, 1) ⥅ (add_arr, 1)
  x ⥅ (add_arr, 2)
  (add_arr, 1) ⥅ z
  c
end

# "x * y + x"
# function twoxy_plus_x_arr(bcast=identity)
#   c = CompArrow(:xyx2, [:x, :y], [:z1, :z2])
#   x, y, z1, z2 = ⬨(c)
#   (x*y)>bcast(2.0)*x ⥅ z1
#   sqrt(y+x*bcast(3.0))<(bcast(3.0)*y+bcast(2.0)) ⥅ z2
#   @grab c
# end

"x * y + x"
function twoxy_plus_x_arr()
  c = CompArrow(:xyx2, [:x, :y], [:z1])
  x, y, z1 = ⬨(c)
  x*y*bsource!(c, 2.0) + x ⥅ z1
  c
end

function sqrt_check()
  c = CompArrow(:sqrtcheck, [:x], [:y])
  x, y = ⬨(c)
  sqrt(x) ⥅ y
  c
end

function abc_arr()
  carr = CompArrow(:abc_arr, [:a, :b, :c], Symbol[])
  a, b, c = ⬨(carr)
  d = a + b * c + a
  e = a + b - c
  Arrows.link_to_parent!(d)
  Arrows.link_to_parent!(e)
  @assert is_valid(carr)
  carr
end

function ifelseconst()
  carr = CompArrow(:ifelseconst, [:a, :b, :c], [:z])
  a, b, c, z = ⬨(carr)
  d = ifelse(c > bsource!(carr, 3),
             a + b,
             a * b)
  d ⥅ z
  @assert is_valid(carr)
  carr
end

function ifelseconstbcast()
  carr = CompArrow(:ifelseconstbcast, [:a, :b, :c], [:z])
  a, b, c, z = ⬨(carr)
  d = ifelse((a + b + c) > bsource!(carr, 3.0),
             bsource!(carr, 4.0),
             bsource!(carr, 7.0))
  d ⥅ z
  @assert is_valid(carr)
  carr
end


function ifelsesimple()
  carr = CompArrow(:ifelsesimple, [:a, :b, :c, :d], [:e])
  a, b, c, d, e = ⬨(carr)
  ee = ifelse(a > b, c, d)
  ee ⥅ e
  @assert is_valid(carr)
  carr
end

function inv_xy_plus_x_arr()
  carr = CompArrow(:inv_xy_plus_x_arr, [:z, :θ], [:x, :y])
  z, θ, x, y = ⬨(carr)
  addprop!(θp, deref(θ))
  invadd = add_sub_arr!(carr, inv_add())
  invmul = add_sub_arr!(carr, inv_mul())
  invdupl = add_sub_arr!(carr, InvDuplArrow(2))

  addz, addθ, addx, addy = ⬨(invadd)
  mulz, mulθ, mulx, muly = ⬨(invmul)
  z ⥅ addz
  addx ⥅ mulz
  θ ⥅ addθ
  addy ⥅ (invdupl, 1)
  mulx ⥅ y
  (invdupl, 1) ⥅ x
  muly ⥅ (invdupl, 2)
  θ ⥅ mulθ
  carr
end

"arrow that computes nth value of fibonnaci sequence"
function fibonnaci_arr()
  c = CompArrow(:fibonnaci_arr, 1, 1)
  c_wrap = add_sub_arr!(c, c)
  x, y = ⬧(c)
  one = add_sub_arr!(c, SourceArrow(1))
  min = add_sub_arr!(c, SubtractArrow())
  ite = add_sub_arr!(c, CondArrow())
  eq = add_sub_arr!(c, EqualArrow())
  add = add_sub_arr!(c, AddArrow())

  # if x == 1
  x ⥅ (eq, 1)
  (one, 1) ⥅ (eq, 2)
  (eq, 1) ⥅ (ite, 1)

  # return x
  (one, 1) ⥅ (ite, 2)

  # f(x - 1)
  x ⥅ (min, 1)
  (one, 1) ⥅ (min, 2)
  (min, 1) ⥅ ▹(c_wrap, 1)

  # x + f(x - 1)
  ◃(c_wrap, 1) ⥅ (add, 1)
  x ⥅ (add, 2)
  (add, 1) ⥅ (ite, 3)
  (ite, 1) ⥅ y
  c
end

fibonnaci_jl(x::Integer) = x == 1 ? 1 : x + fib(x - 1)

# "f(x) = id(x), id(x)"
# function dupl_id_arr()
#   c = CompArrow(:dupl_id, 1, 2)
#   id1 = add_sub_arr!(c, IdentityArrow())
#   id2 = add_sub_arr!(c, IdentityArrow())
#   x, y, z = ⬧(c)
#   x ⥅ (id1, 1)
#   x ⥅ (id2, 1)
#   (id1, 1) ⥅ y
#   (id2, 1) ⥅ z
#   c
# end

"f(x) = if p(x) then p(x), f(x)[1] else p(x), g(f(x)[2])"
function det_policy_inner_arr()
  c = CompArrow(:det_policy_inner_arr, 1, 2)
  f = add_sub_arr!(c, dupl_id_arr())
  p = add_sub_arr!(c, IdentityArrow())
  g = add_sub_arr!(c, IdentityArrow())
  ite = add_sub_arr!(c, CondArrow())

  (c, 1) ⥅ (p, 1)
  (p, 1) ⥅ (c, 1)
  (p, 1) ⥅ (ite, 1)
  (c, 1) ⥅ (f, 1)
  (f, 1) ⥅ (ite, 2)
  (f, 2) ⥅ (g, 1)
  (g, 1) ⥅ (ite, 3)
  (ite, 1) ⥅ (c, 2)
  c
end

"f(x,y) = (x+y) + (x+y)"
function triple_add()
  c = CompArrow(:triple_add, 2, 1)
  x, y, z = ⬧(c)
  a1 = Arrows.add_sub_arr!(c, Arrows.AddArrow())
  a2 = Arrows.add_sub_arr!(c, Arrows.AddArrow())
  a3 = Arrows.add_sub_arr!(c, Arrows.AddArrow())
  x ⥅ (a1, 1)
  x ⥅ (a2, 1)
  y ⥅ (a1, 2)
  y ⥅ (a2, 2)
  (a1, 1) ⥅ (a3, 1)
  (a2, 1) ⥅ (a3, 2)
  (a3, 1) ⥅ z
  c
end

function test_two_op()
  carr = CompArrow(:test_two_op, [:x, :y], [:a, :b])
  x, y, a, b = ⬨(carr)
  z = x + y
  c = y * z
  c ⥅ a
  z ⥅ b
  carr
end

function weird_arr()
  carr = CompArrow(:weird, [:x, :y, :z], [:a, :b])
  x, y, z, a, b = ⬨(carr)
  e = z * x + y * bsource!(carr, 3.0) * z + y
  f = e * x + y
  g = bsource!(arr, 6.0)*x+x
  h = f * g
  h ⥅ a
  g ⥅ b
  @assert is_valid(carr)
  carr
end

function cond_arr_eq()
  c = CompArrow(:cond_arr_eq, [:x, :y], [:z])
  x, y, z = ⬧(c)
  eq = add_sub_arr!(c, EqualArrow())
  ite = add_sub_arr!(c, CondArrow())
  x ⥅ (eq, 1)
  y ⥅ (eq, 2)
  (eq, 1) ⥅ (ite, 1)
  x ⥅ (ite, 2)
  y ⥅ (ite, 3)
  (ite, 1)  ⥅ z
  @assert is_valid(c)
  c
end

"Make a nested function with `core_arrow` at core, `nlevels` levels deep"
function nested_core(nlevels=3, core_arrow=SqrtArrow())
  carr1 = CompArrow(:nested_core, [:x], [:y])
  parr = carr1
  sarrs = []
  local carr
  for i = 1:nlevels
    carr = CompArrow(Symbol(:nested_l, i + 1), [:x], [:y])
    sarr = add_sub_arr!(parr, carr)
    push!(sarrs, sarr)
    parr = carr
  end

  sarr = add_sub_arr!(carr, core_arrow)
  push!(sarrs, sarr)
  for sarr in reverse(sarrs)
    x, y = ⬨(sarr)
    xx, yy = ⬨(parent(sarr))
    xx ⥅ x
    y ⥅ yy
  end
  carr1
end

"Tests functions with far flung constants"
function test_chain_invert()
  carr = CompArrow(:cx, [:x], [:y])
  x, y = get_sub_ports(carr)
  src = add_sub_arr!(carr, source(1.0))
  sqrtx = exp(get_sub_ports(src, 1))
  x + sqrtx ⥅ y
  @assert is_valid(carr)
  carr
end

function test_nested()
  carr = CompArrow(:test_out_neigh, [:x], [:y1, :y2, :y3])
  icarr = CompArrow(:inner_test_out_neigh, [:a], [:b1, :b2, :b3])
  a, b1, b2, b3 = get_sub_ports(icarr)
  b = sqrt(a)
  cos(b) ⥅ b1
  b ⥅ b2
  b ⥅ b3
  @assert is_valid(icarr)

  x, y1, y2, y3 = get_sub_ports(carr)
  oy1, oy2, oy3 = icarr(x)
  oy1 ⥅ y1
  sin(oy2) ⥅ y2
  oy3 ⥅ y3
  @assert is_valid(carr)
  carr
end

function easyarrs()
  [xy_plus_x_arr(),
   det_policy_inner_arr(),
   triple_add()]
end

"all test arrows"
function all_test_arrows()
  [xy_plus_x_arr(),
   fibonnaci_arr(),
  #  dupl_id_arr(), #FIXME: readdme, disabled to make traiining work
  #  det_policy_inner_arr(),
   triple_add(),
  #  weird_arr(),
   nested_core(),
   ifelsesimple(),
   ifelseconst(),
   twoxy_plus_x_arr()]
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
       plain_arrows,
       cond_arr_eq
end
