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

function inv(::GatherNdArrow, sarr::SubArrow, abvals::IdAbValues)
  Arrows.inv_gather(), Dict(1=>5, 2=>2, 3=>3, 4=>1)
end

function inv(arr::AddArrow, sarr::SubArrow, abvals::IdAbValues)
  binary_inv(arr,
             const_in(arr, abvals),
             inv_add,
             SubtractArrow,
             Dict(1 => 2, 2 => 3, 3 => 1),
             SubtractArrow,
             Dict(3 => 1, 2 => 2, 1 => 3))
end

function inv(arr::SubtractArrow, sarr::SubArrow, abvals::IdAbValues)
  binary_inv(arr,
             const_in(arr, abvals),
             inv_sub,
             AddArrow,
             Dict(1 => 1, 2 => 3, 3 => 2),
             AddArrow,
             Dict(1 => 3, 2 => 2, 3 => 1))
end

function inv(arr::MulArrow, sarr::SubArrow, idabv::IdAbValues)
  # @show idabv
  binary_inv(arr,
             const_in(arr, idabv),
             inv_mul,
             DivArrow,
             Dict(1 => 2, 2 => 3, 3 => 1),
             DivArrow,
             Dict(1 => 3, 2 => 2, 3 => 1))
end

function inv_np(arr::CosArrow, sarr::SubArrow, abvals::IdAbValues)
   unary_inv(arr, const_in(arr, abvals), ACosArrow)
end

function inv_np(arr::SinArrow, sarr::SubArrow,  abvals::IdAbValues)
   unary_inv(arr, const_in(arr, abvals), ASinArrow)
 end

"The parametric inverse of cos, cos^(-1)(y; θ) = 2π * ceil(θ/2) + (-1)^θ * acos(y)."
function inv(arr::CosArrow, sarr::SubArrow, abvals::IdAbValues)
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
function inv(arr::SinArrow, sarr::SubArrow, abvals::IdAbValues)
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

function inv(arr::ExpArrow, sarr::SubArrow, abvals::IdAbValues)
  unary_inv(arr, const_in(arr, abvals), LogArrow)
end

function inv(arr::SourceArrow, sarr::SubArrow, abvals::IdAbValues)
  (SourceArrow(arr.value), Dict(1 => 1))
end

function inv(arr::NegArrow, sarr::SubArrow, abvals::IdAbValues)
  unary_inv(arr, const_in(arr, abvals), NegArrow)
end

function inv(arr::IdentityArrow, sarr::SubArrow, abvals::IdAbValues)
  unary_inv(arr, const_in(arr, abvals), IdentityArrow)
end

# function inv(arr::AssertArrow, sarr::SubArrow, abvals::IdAbValues)
#   SourceArrow(true), Dict(1 => 1)
# end
