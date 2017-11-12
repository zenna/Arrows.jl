# Inequalities #
const ineq_props = [Props(true, :x, Real),
                    Props(true, :y, Real),
                    Props(false, :z, Bool)]

## Greater Than ##
"x > y"
struct GreaterThanArrow <: PrimArrow end
name(::GreaterThanArrow)::Symbol = :>
props(::GreaterThanArrow) = ineq_props

propcheck(port_id, prop, tvals, abtvals) =
  tvals[1] ∈ keys(abtvals) && [:value] in keys(abtvals[tvals[1]])

function inv(arr::GreaterThanArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  tarr = TraceSubArrow(tparent, sarr)
  tvals = trace_values(tarr)
  !any(tval in keys(abtvals) for tval in tvals)

  # If the first port is known to bte constant
  if tvals[1] ∈ keys(abtvals) && [:value] in keys(abtvals[tvals[1]])
    inv_gt_xcnst(), Dict(:x => :x, :y => :y, :z => :z)
  elseif tvals[2] ∈ keys(abtvals) && [:value] in keys(abtvals[tvals[1]])
    inv_gt_ycnst(), Dict(:x => :x, :y => :y, :z => :z)
  else
    inv_gt_arr(), Dict(:x => :x, :y => :y, :z => :z)
  end
end

# # Z is const
# function inv_gt_arr()
#   carr = CompArrow(:inv_gt, [:z, :y, :θinv_gt_arr], [:x])
#   z, y, θ, x = ⬨(carr)
#   addprop!(θp, deref(θ))
#   assert!(z)
#   (abs(θ) + y) ⥅ x
#   carr
# end

"Complete parameric inverse for >"
function inv_gt_ycnst()
  carr = CompArrow(:inv_gt_xcnst, [:z, :y, :θ], [:x])
  z, y, θ, x = ⬨(carr)
  ifelse(z, y + abs(θ), y - abs(θ)) ⥅ x
  @assert is_wired_ok(carr)
  carr
end

"Complete parameric inverse for >"
function inv_gt_xcnst()
  carr = CompArrow(:inv_gt_xcnst, [:z, :x, :θ], [:y])
  z, x, θ, y = ⬨(carr)
  ifelse(z, x - abs(θ), x + abs(θ)) ⥅ y
  @assert is_wired_ok(carr)
  carr
end

function inv_gt_arr()
  carr = CompArrow(:inv_gt, [:z, :θ1, :θ2], [:x, :y])
  z, θ1, θ2, x, y = ⬨(carr)
  θ1 ⥅ x
  ifelse(z, θ1 - θ2, θ1 + θ2) ⥅ y
  @assert is_wired_ok(carr)
  carr
end

"x >= y"
struct GreaterThanEqualArrow <: PrimArrow end
name(::GreaterThanEqualArrow)::Symbol = :(>=)
props(::GreaterThanEqualArrow) = ineq_props

"x <= y"
struct LessThanEqualArrow <: PrimArrow end
name(::LessThanEqualArrow)::Symbol = :(<=)
props(::LessThanEqualArrow) = ineq_props

function inv(arr::LessThanArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  (inv_lt_arr(), Dict(1 => 4, 2 => 2, 3 => 1))
end

"Complete parameric inverse for >"
function inv_lt_ycnst()
  carr = CompArrow(:inv_lt_xcnst, [:z, :y, :θ], [:x])
  z, y, θ, x = ⬨(carr)
  ifelse(z, y + abs(θ), y - abs(θ)) ⥅ x
  @assert is_wired_ok(carr)
  carr
end

"Complete parameric inverse for >"
function inv_lt_xcnst()
  carr = CompArrow(:inv_lt_xcnst, [:z, :x, :θ], [:y])
  z, x, θ, y = ⬨(carr)
  ifelse(z, x - abs(θ), x + abs(θ)) ⥅ y
  @assert is_wired_ok(carr)
  carr
end

function inv_lt_arr()
  carr = CompArrow(:inv_lt, [:z, :θ1, :θ2], [:x, :y])
  z, θ1, θ2, x, y = ⬨(carr)
  θ1 ⥅ x
  ifelse(z, θ1 - θ2, θ1 + θ2) ⥅ y
  @assert is_wired_ok(carr)
  carr
end


# function inv_lt_arr()
#   carr = CompArrow(:inv_gt, [:z, :y, :θinv_lt_arr], [:x])
#   z, y, θ, x = ⬨(carr)
#   addprop!(θp, deref(θ))
#   assert!(z)
#   (y - abs(θ)) ⥅ x
#   carr
# end

"x < y"
struct LessThanArrow <: PrimArrow end
name(::LessThanArrow)::Symbol = :(<)
props(::LessThanArrow) = ineq_props

# Equality #

"Takes no input simple emits a `value::T`"
struct EqualArrow <: PrimArrow end
name(::EqualArrow) = :(==)
props(::EqualArrow) = ineq_props

IneqArrows = Union{GreaterThanArrow,
                   GreaterThanEqualArrow,
                   LessThanEqualArrow,
                   LessThanArrow,
                   EqualArrow}
abinterprets(::IneqArrows) = [sizeprop]
isscalar(::Type{<:IneqArrows}) = Val{true}
isscalar(::IneqArrows) = true
