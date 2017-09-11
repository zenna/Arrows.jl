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
  @show const_in
  if xconst && yconst
    # If both ports constant just return arrow as is
    invarr = deepcopy(arr)
    port_map = iden_port_map(arr)
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
    port_map = iden_port_map(arr)
  else
    invarr = inv_arr()
    port_map = inv_port_map
  end
  invarr, port_map
end

inv{O}(arr::DuplArrow{O}, const_in::Vector{Bool}) =
  (InvDuplArrow(O), merge(Dict(1 => O + 1), Dict(i => i - 1 for i = 2:O+1)))

inv(arr::AddArrow, const_in) =
  binary_inv(arr,
              const_in,
              inv_add,
              SubArrow,
              Dict(1 => 2, 2 => 3, 3 => 1),
              SubArrow,
              Dict(0 => 2, 1 => 1, 2 => 0))

inv(arr::SubtractArrow, const_in) =
  binary_inv(arr,
             const_in,
             inv_sub,
             SubArrow,
             Dict(1 => 1, 2 => 3, 3 => 2),
             AddArrow,
             Dict(1 => 3, 2 => 2, 3 => 1))

inv(arr::MulArrow, const_in) =
  binary_inv(arr,
             const_in,
             inv_mul,
             DivArrow,
             Dict(1 => 2, 2 => 3, 3 => 1),
             DivArrow,
             Dict(0 => 2, 1 => 1, 2 => 0))

inv(arr::CosArrow, const_in) = unary_inv(arr, const_in, ACosArrow)
inv(arr::SinArrow, const_in) = unary_inv(arr, const_in, ASinArrow)
inv(arr::ExpArrow, const_in) = unary_inv(arr, const_in, LogArrow)

inv(arr::SourceArrow, const_in::Vector{Bool}) = (SourceArrow(arr.value), Dict(1 => 1))

inv(arr::NegArrow, const_in) = unary_inv(arr, const_in, NegArrow)
inv(arr::IdentityArrow, const_in) = unary_inv(arr, const_in, IdentityArrow)

inv(arr::AssertArrow, const_in::Vector{Bool}) = (SourceArrow(true), Dict(1 => 1))
inv(arr::GreaterThanArrow, const_in::Vector{Bool}) = (inv_gt_arr(), Dict(1 => 4, 2 => 2, 3 => 1))
inv(arr::LessThanArrow, const_in::Vector{Bool}) = (inv_lt_arr(), Dict(1 => 4, 2 => 2, 3 => 1))

function inv_gt_arr()
  carr = CompArrow(:inv_gt, [:z, :y, :θinv_gt_arr], [:x])
  z, y, θ, x = sub_ports(carr)
  set_parameter_port!(deref(θ))
  assert!(z)
  (abs(θ) + y) ⥅ x
  carr
end

function inv_lt_arr()
  carr = CompArrow(:inv_gt, [:z, :y, :θinv_lt_arr], [:x])
  z, y, θ, x = sub_ports(carr)
  set_parameter_port!(deref(θ))
  assert!(z)
  (y - abs(θ)) ⥅ x
  carr
end
