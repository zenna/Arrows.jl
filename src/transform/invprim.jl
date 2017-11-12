# FIXME: Switch to symbols instead of numbers
# TODO: Add is_valid for These portmaps to check
const BIN_PORT_MAP = Dict(1 => 3, 2 => 4, 3 => 1)

"Generic helper for inversion of binary functions"
function binary_inv(arr::Arrow,
                    const_in::Vector{Bool},
                    inv_arr,
                    xconstarr, xconstportmap,
                    yconstarr, yconstportmap)
  xconst, yconst = const_in
  if xconst && yconst
    # If both ports constant just return arrow as is
    invarr = deepcopy(arr)
    port_map = id_portid_map(arr)
  elseif xconst
    invarr = xconstarr()
    port_map = xconstportmap
  elseif yconst
    invarr = yconstarr()
    port_map = yconstportmap
  else
    # Neither constant, do 'normal' parametric inversison
    invarr = inv_arr()
    port_map = BIN_PORT_MAP
  end
  return invarr, port_map
end

function unary_inv(arr::Arrow,
                   const_in::Vector{Bool},
                   inv_arr,
                   inv_port_map = Dict(1 => 2, 2 => 1))
  xconst, = const_in
  if xconst
    invarr = deepcopy(arr)
    port_map = id_portid_map(arr)
  else
    invarr = inv_arr()
    port_map = inv_port_map
  end
  invarr, port_map
end

"Inverse reshape must take the shape of `value`"
function inv(::Arrows.ReshapeArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  const_in[2] || throw(ArgumentError("Nonconst indices unimplemented"))

  # The input shape to the inverse is shape of the input to the forward arr
  tarr = TraceSubArrow(tparent, sarr)
  tvals = trace_values(tarr)
  # @show tvals[1] ∈ abtvals
  sz = abtvals[tvals[1]][:size]
  source = SourceArrow(get(sz))
  carr = CompArrow(:inv_reshape_comp, [:z], [:x])
  z, x = ⬨(carr)
  srcsarr = add_sub_arr!(carr, source)
  rshparr = add_sub_arr!(carr, ReshapeArrow())
  z ⥅ (rshparr, 1)
  (srcsarr, 1) ⥅ (rshparr, 2)
  (rshparr, 1) ⥅ x
  @assert is_wired_ok(carr)
  carr, Dict(3=>1, 1=>2)
end

function inv(::Arrows.GatherNdArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  Arrows.inv_gather(), Dict(1=>5, 2=>2, 3=>3, 4=>1)
end

function inv{O}(::Arrows.DuplArrow{O},
                sarr::SubArrow,
                const_in::Vector{Bool},
                tparent::TraceParent,
                abtvals::AbTraceValues)
  (InvDuplArrow(O), merge(Dict(1 => O + 1), Dict(i => i - 1 for i = 2:O+1)))
end

function inv(arr::AddArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  binary_inv(arr,
              const_in,
              inv_add,
              SubtractArrow,
              Dict(1 => 2, 2 => 3, 3 => 1),
              SubtractArrow,
              Dict(3 => 1, 2 => 2, 1 => 3))
end

function inv(arr::SubtractArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  binary_inv(arr,
             const_in,
             inv_sub,
             AddArrow,
             Dict(1 => 1, 2 => 3, 3 => 2),
             AddArrow,
             Dict(1 => 3, 2 => 2, 3 => 1))
end

function inv(arr::MulArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  binary_inv(arr,
             const_in,
             inv_mul,
             DivArrow,
             Dict(1 => 2, 2 => 3, 3 => 1),
             DivArrow,
             Dict(1 => 3, 2 => 2, 3 => 1))
end

function inv_np(arr::CosArrow,
                sarr::SubArrow,
                const_in::Vector{Bool},
                tparent::TraceParent,
                abtvals::AbTraceValues)
   unary_inv(arr, const_in, ACosArrow)
end

function inv_np(arr::SinArrow,
                sarr::SubArrow,
                const_in::Vector{Bool},
                tparent::TraceParent,
                abtvals::AbTraceValues)
   unary_inv(arr, const_in, ASinArrow)
 end

 "The parametric inverse of cos, cos^(-1)(y; θ) = 2π * ceil(θ/2) + (-1)^θ * acos(y)."
 function inv(arr::CosArrow,
              sarr::SubArrow,
              const_in::Vector{Bool},
              tparent::TraceParent,
              abtvals::AbTraceValues)
  inv_cos = CompArrow(:inv_cos, [:y, :θ], [:x])
  y, θ, x = sub_ports(inv_cos)
  addprop!(θp, deref(θ))
  twoπ = add_sub_arr!(inv_cos, SourceArrow(2 * π))
  two = add_sub_arr!(inv_cos, SourceArrow(2.0))
  mul1 = add_sub_arr!(inv_cos, MulArrow())
  div = add_sub_arr!(inv_cos, DivArrow())
  ceil = add_sub_arr!(inv_cos, CeilArrow())
  link_ports!(θ, (div, 1))
  link_ports!((two, 1), (div, 2))
  link_ports!((div, 1), (ceil, 1))
  link_ports!((ceil, 1), (mul1, 1))
  link_ports!((twoπ, 1), (mul1, 2))
  # the output of mul1 represents 2π * ceil(θ/2).

  negativeone = add_sub_arr!(inv_cos, SourceArrow(-1.0))
  one = add_sub_arr!(inv_cos, SourceArrow(1.0))
  zero = add_sub_arr!(inv_cos, SourceArrow(0.0))
  mod = add_sub_arr!(inv_cos, ModArrow())
  equals = add_sub_arr!(inv_cos, EqualArrow())
  ifelse = add_sub_arr!(inv_cos, IfElseArrow())
  link_ports!(θ, (mod, 1))
  link_ports!((two, 1), (mod, 2))
  link_ports!((mod, 1), (equals, 1))
  link_ports!((zero, 1), (equals, 2))
  link_ports!((equals, 1), (ifelse, 1))
  link_ports!((one, 1), (ifelse, 2))
  link_ports!((negativeone, 1), (ifelse, 3))
  # the output of ifelse represents (-1)^θ = (θ % 2 == 0? 1 : -1).

  mul2 = add_sub_arr!(inv_cos, MulArrow())
  acos = add_sub_arr!(inv_cos, ACosArrow())
  link_ports!(y, (acos, 1))
  link_ports!((acos, 1), (mul2, 1))
  link_ports!((ifelse, 1), (mul2, 2))
  add = add_sub_arr!(inv_cos, AddArrow())
  link_ports!((mul1, 1), (add, 1))
  link_ports!((mul2, 1), (add, 2))
  link_ports!((add, 1), x)
  inv_cos, Dict(1 => 3, 2 => 1)
end

"The parametric inverse of sin, sin^(-1)(y; θ) = πθ + (-1)^θ * asin(y)."
# (-1)^θ is implemented as θ % 2 == 0 ? 1 : -1
function inv(arr::SinArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  inv_sin = CompArrow(:inv_sin, [:y, :θ], [:x])
  y, θ, x = sub_ports(inv_sin)
  addprop!(θp, deref(θ))
  pi = add_sub_arr!(inv_sin, SourceArrow(π))
  mul1 = add_sub_arr!(inv_sin, MulArrow())
  link_ports!(θ, (mul1, 1))
  link_ports!((pi, 1), (mul1, 2))
  # the output of mul1 represents πθ

  negativeone = add_sub_arr!(inv_sin, SourceArrow(-1.0))
  one = add_sub_arr!(inv_sin, SourceArrow(1.0))
  zero = add_sub_arr!(inv_sin, SourceArrow(0.0))
  two = add_sub_arr!(inv_sin, SourceArrow(2.0))
  mod = add_sub_arr!(inv_sin, ModArrow())
  equals = add_sub_arr!(inv_sin, EqualArrow())
  ifelse = add_sub_arr!(inv_sin, IfElseArrow())
  link_ports!(θ, (mod, 1))
  link_ports!((two, 1), (mod, 2))
  link_ports!((mod, 1), (equals, 1))
  link_ports!((zero, 1), (equals, 2))
  link_ports!((equals, 1), (ifelse, 1))
  link_ports!((one, 1), (ifelse, 2))
  link_ports!((negativeone, 1), (ifelse, 3))
  # the output of ifelse represents (-1)^θ = (θ % 2 == 0 ? 1 : -1).

  mul2 = add_sub_arr!(inv_sin, MulArrow())
  asin = add_sub_arr!(inv_sin, ASinArrow())
  link_ports!(y, (asin, 1))
  link_ports!((asin, 1), (mul2, 1))
  link_ports!((ifelse, 1), (mul2, 2))
  add = add_sub_arr!(inv_sin, AddArrow())
  link_ports!((mul1, 1), (add, 1))
  link_ports!((mul2, 1), (add, 2))
  link_ports!((add, 1), x)
  inv_sin, Dict(1 => 3, 2 => 1)
end

function inv(arr::ExpArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  unary_inv(arr, const_in, LogArrow)
end

function inv(arr::SourceArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  (SourceArrow(arr.value), Dict(1 => 1))
end

function inv(arr::NegArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  unary_inv(arr, const_in, NegArrow)
end

function inv(arr::IdentityArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  unary_inv(arr, const_in, IdentityArrow)
end

function inv(arr::AssertArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  (SourceArrow(true), Dict(1 => 1))
end

function inv(arr::GreaterThanArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  tarr = TraceSubArrow(tparent, sarr)
  tvals = trace_values(tarr)
  @show any(tval in keys(abtvals) for tval in tvals)
  # sz = abtvals[tvals[1]][:size]
  (inv_gt_arr(), Dict(1 => 4, 2 => 2, 3 => 1))
end

function inv_gt_arr()
  carr = CompArrow(:inv_gt, [:z, :y, :θinv_gt_arr], [:x])
  z, y, θ, x = ⬨(carr)
  addprop!(θp, deref(θ))
  assert!(z)
  (abs(θ) + y) ⥅ x
  carr
end

function inv(arr::LessThanArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  (inv_lt_arr(), Dict(1 => 4, 2 => 2, 3 => 1))
end

function inv_lt_arr()
  carr = CompArrow(:inv_gt, [:z, :y, :θinv_lt_arr], [:x])
  z, y, θ, x = ⬨(carr)
  addprop!(θp, deref(θ))
  assert!(z)
  (y - abs(θ)) ⥅ x
  carr
end

function inv(arr::SqrtArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  SqrArrow(), Dict(1=>2, 2=>1)
end
