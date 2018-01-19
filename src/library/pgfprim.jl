"This file contains the pgfs of primitive arrows."

# FIXME: at the moment all of the pgfs are manually constructed.
# at least want to just add the parameter part to the arrow and
# not have to construct the arrow along with the parameter.

function binary_pgf(arr, const_in, inner_pgf)
  if const_in[1] || const_in[2]
    deepcopy(arr)
  else
    inner_pgf()
  end
end

pgf(arr::MulArrow, const_in) = binary_pgf(arr, const_in, pgf_mul)
pgf(arr::XorArrow, const_in) = binary_pgf(arr, const_in, pgf_xor)
pgf(arr::AddArrow, const_in) = binary_pgf(arr, const_in, pgf_add)
pgf(arr::SubtractArrow, const_in) = binary_pgf(arr, const_in, pgf_sub)
pgf(arr::DivArrow, const_in) = binary_pgf(arr, const_in, pgf_div)

function pgf_mul()
  "As f^(-1)(z; θ) = (z/θ, θ), then the pgf becomes r(x, y) = (x*y, y)."
  carr = CompArrow(Symbol(:pgf_, :mul), [:x, :y], [:z, :θmul])
  x, y, z, θ = ⬨(carr)
  x * y ⥅ z
  y ⥅ θ
  carr
end

function pgf_xor()
  "As f^(-1)(z; θ) = (z ⊻ θ, θ), then the pgf becomes r(x, y) = (x ⊻ y, y)."
  carr = CompArrow(Symbol(:pgf_, :xor), [:x, :y], [:z, :θxor])
  x, y, z, θ = ⬨(carr)
  x ⊻ y ⥅ z
  y ⥅ θ
  carr
end

function pgf_add()
  "As f^(-1)(z; θ) = (z-θ, θ), then the pgf becomes r(x, y) = (x+y, y)."
  carr = CompArrow(Symbol(:pgf_, :add), [:x, :y], [:z, :θadd])
  x, y, z, θ = ⬨(carr)
  x + y ⥅ z
  y ⥅ θ
  carr
end

function pgf_sub()
  "As f^(-1)(z; θ) = (z+θ, θ), then the pgf becomes r(x, y) = (x-y, y)."
  carr = CompArrow(Symbol(:pgf_, :sub), [:x, :y], [:z, :θ])
  x, y, z, θ = ⬨(carr)
  x - y ⥅ z
  y ⥅ θ
  carr
end


function pgf(arr::GatherNdArrow, const_in)
  carr = CompArrow(Symbol(:pgf_, :sub),
                      [:param, :indices, :shape],
                      [:z, :θgather])
  param, indices, shape, z, θ = ⬨(carr)
  sarr = add_sub_arr!(carr, GatherNdArrow())
  param ⥅ (sarr, 1)
  indices ⥅ (sarr, 2)
  shape ⥅ (sarr, 3)
  (sarr, 1) ⥅ z
  scatter = add_sub_arr!(carr, ScatterNdArrow())
  (sarr, 1) ⥅ (scatter, 1)
  indices ⥅ (scatter, 2)
  shape ⥅ (scatter, 3)
  (param - ◃(scatter, 1)) ⥅ θ
  carr
end

function pgf(arr::SinArrow, const_in)
  "As f^(-1)(y; θ) = πθ + (-1)^θ * asin(y), then the pgf becomes θ = floor((x+π/2)/π)."
  carr = CompArrow(Symbol(:pgf_, :sin), [:x], [:y, :θsin])
  x, y, θ = sub_ports(carr)
  sinarr = add_sub_arr!(carr, SinArrow())
  link_ports!(x, (sinarr, 1))
  link_ports!((sinarr, 1), y)
  pihalf = add_sub_arr!(carr, SourceArrow(π/2))
  pi = add_sub_arr!(carr, SourceArrow(π))
  add = add_sub_arr!(carr, AddArrow())
  div = add_sub_arr!(carr, DivArrow())
  floor = add_sub_arr!(carr, FloorArrow())
  link_ports!(x, (add, 1))
  link_ports!((pihalf, 1), (add, 2))
  link_ports!((add, 1), (div, 1))
  link_ports!((pi, 1), (div, 2))
  link_ports!((div, 1), (floor, 1))
  link_ports!((floor, 1), θ)
  carr
end

function pgf(arr::CosArrow, const_in)
  "As f^(-1)(y; θ) = 2π * ceil(θ/2) + (-1)^θ * acos(y), then the pgf becomes θ = floor(x/π)."
  carr = CompArrow(Symbol(:pgf_, :cos), [:x], [:y, :θcos])
  x, y, θ = sub_ports(carr)
  cosarr = add_sub_arr!(carr, CosArrow())
  link_ports!(x, (cosarr, 1))
  link_ports!((cosarr, 1), y)
  pi = add_sub_arr!(carr, SourceArrow(π))
  div = add_sub_arr!(carr, DivArrow())
  floor = add_sub_arr!(carr, FloorArrow())
  link_ports!(x, (div, 1))
  link_ports!((pi, 1), (div, 2))
  link_ports!((div, 1), (floor, 1))
  link_ports!((floor, 1), θ)
  carr
end

function pgf_div()
  carr = CompArrow(Symbol(:pgf_, :div), [:x, :y], [:z, :θdiv])
  x, y, z, θ = ⬨(carr)
  x / y ⥅ z
  y ⥅ θ
  carr
end

"""
Three cases:
x is constant: f^(-1)(z; x, θ1) = (z ?  x - abs(θ1) : x + abs(θ1))
y is constant: f^(-1)(z; θ1, y) = (z ?  y + abs(θ1) : y - abs(θ1))
none is constant: f^(-1)(z; θ1, θ2) = (θ1, z ?  θ1 - θ2 : θ1 + θ2)
"""
function pgf(arr::GreaterThanArrow, const_in)
  xconst, yconst = const_in
  if xconst
    carr = CompArrow(Symbol(:pgf_, :gt_xcnst), [:x, :y], [:z, :θgt])
    x, y, z, θgt = ⬨(carr)
    x > y ⥅ z
    y - x ⥅ θgt
  elseif yconst
    carr = CompArrow(Symbol(:pgf_, :gt_ycnst), [:x, :y], [:z, :θgt])
    x, y, z, θgt = ⬨(carr)
    x > y ⥅ z
    x - y ⥅ θgt
  else
    carr = CompArrow(Symbol(:pgf_, :gt), [:x, :y], [:z, :θgt1, :θgt2])
    x, y, z, θgt1, θgt2 = ⬨(carr)
    x > y ⥅ z
    x ⥅ θgt1
    x - y ⥅ θgt2
  end
  carr
end

function pgf(arr::ModArrow, const_in)
  @assert const_in[2]
  carr = CompArrow(:pgf_mod, [:x, :y], [:z, :θmod])
  x, y, z, θ = ⬨(carr)
  x % y ⥅ z
  div((x - z), y) ⥅ θ
  carr
end

function pgf(arr::LessThanArrow, const_in)
  "As f^(-1)(z; θ1, θ2) = (θ1, [θ1+θ2, θ1-θ2]^z), then the pgf becomes r(x, y) = (x<y, x, abs(x-y))."
  carr = CompArrow(Symbol(:pgf_, :lessthan), [:x, :y], [:z, :θ1, :θ2])
  x, y, z, θ1, θ2 = ⬨(carr)
  abs = add_sub_arr!(carr, AbsArrow())
  x < y ⥅ z
  x ⥅ θ1
  x - y ⥅ (abs, 1)
  link_ports!((abs, 2), θ2)
  carr
end


function pgf(arr::IfElseArrow, const_in)
  if const_in[2] && const_in[3]
    carr = CompArrow(:ifelse_teconst_pgf,
                      [:i, :t, :e],
                      [:y, :θi])
    i, t, e = ▹(carr)
    θi, = ◃(carr)
    i ⥅ θi
  elseif const_in[2]
    carr = CompArrow(:ifelse_tconst_pgf,
                      [:i, :t, :e],
                      [:θi, :θmissing])
    i, t, e = ▹(carr)
    θi, θmissing = ◃(carr)
    i ⥅ θi
    e ⥅ θmissing
  elseif const_in[3]
    carr = CompArrow(:ifelse_econst_pgf,
                      [:i, :t, :e],
                      [:y, :θi, :θmissing])
    i, t, e = ▹(carr)
    y, e, θi, θmissing = ◃(carr)
    i ⥅ θi
    t ⥅ θmissing
  elseif all(i->!const_in[i], port_id.(get_in_ports(arr)))
    carr = CompArrow(:ifelse_nonconst_pgf,
                      [:i, :t, :e],
                      [:y, :θi, :θmissing])
    i, t, e = ▹(carr)
    y, θi, θmissing = ◃(carr)
    i ⥅ θi
    ifelse(i, e, t) ⥅ θmissing
  else
    throw(ArgumentError("Constness Combination not supported"))
  end
  ifelse(i, t, e) ⥅ y
  carr
end
