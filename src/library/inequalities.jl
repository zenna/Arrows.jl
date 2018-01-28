# Inequalities #
const ineq_props = [Props(true, :x, Real),
                    Props(true, :y, Real),
                    Props(false, :z, Bool)]

## Greater Than ##
"x > y"
struct GreaterThanArrow <: PrimArrow end
name(::GreaterThanArrow)::Symbol = :>
props(::GreaterThanArrow) = ineq_props

function inv(arr::GreaterThanArrow, sarr::SubArrow, idabv::IdAbVals)
  if isconst(1, idabv)
    inv_gt_xcnst(), Dict(:x => :x, :y => :y, :z => :z)
  elseif isconst(2, idabv)
    inv_gt_ycnst(), Dict(:x => :x, :y => :y, :z => :z)
  elseif isconst(3, idabv)
    throw(InvertError(arr, idabv))
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
  carr = CompArrow(:inv_gt_ycnst, [:z, :y, :θgt], [:x])
  z, y, θgt, x = ⬨(carr)
  ifelse(z, y + abs(θgt), y - abs(θgt)) ⥅ x
  foreach(add!(θp), (θgt,))
  @assert is_wired_ok(carr)
  carr
end

"Complete parameric inverse for >"
function inv_gt_xcnst()
  carr = CompArrow(:inv_gt_xcnst, [:z, :x, :θgt], [:y])
  z, x, θgt, y = ⬨(carr)
  ifelse(z, x - abs(θgt), x + abs(θgt)) ⥅ y
  foreach(add!(θp), (θgt, ))
  @assert is_wired_ok(carr)
  carr
end

function inv_gt_arr()
  carr = CompArrow(:inv_gt, [:z, :θgt1, :θgt2], [:x, :y])
  z, θgt1, θgt2, x, y = ⬨(carr)
  θgt1 ⥅ x
  ifelse(z, θgt1 - θgt2, θgt1 + θgt2) ⥅ y
  foreach(add!(θp), (θgt1, θgt2))
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

# function inv_lt_arr()
#   carr = CompArrow(:inv_gt, [:z, :y, :θgtinv_lt_arr], [:x])
#   z, y, θgt, x = ⬨(carr)
#   addprop!(θgtp, deref(θgt))
#   assert!(z)
#   (y - abs(θgt)) ⥅ x
#   carr
# end

"x < y"
struct LessThanArrow <: PrimArrow end
name(::LessThanArrow)::Symbol = :(<)
props(::LessThanArrow) = ineq_props

function inv(arr::LessThanArrow, sarr::SubArrow, idabv::IdAbVals)
  if isconst(1, idabv)
    # @assert false
    inv_lt_xcnst(), Dict(:x => :x, :y => :y, :z => :z)
  elseif isconst(2, idabv)
    # @assert false
    inv_lt_ycnst(), Dict(:x => :x, :y => :y, :z => :z)
  else
    inv_lt_arr(), Dict(:x => :x, :y => :y, :z => :z)
  end
end

"Complete parameric inverse for >"
function inv_lt_ycnst()
  carr = CompArrow(:inv_lt_xcnst, [:z, :y, :θlt], [:x])
  z, y, θlt, x = ⬨(carr)
  ifelse(z,  y - abs(θlt), y + abs(θlt)) ⥅ x
  foreach(add!(θp), (θlt,))
  @assert is_wired_ok(carr)
  carr
end

"Complete parameric inverse for >"
function inv_lt_xcnst()
  carr = CompArrow(:inv_lt_xcnst, [:z, :x, :θlt], [:y])
  z, x, θlt, y = ⬨(carr)
  ifelse(z, x + abs(θlt), x - abs(θlt)) ⥅ y
  foreach(add!(θp), (θlt,))
  @assert is_wired_ok(carr)
  carr
end

function inv_lt_arr()
  carr = CompArrow(:inv_lt, [:z, :θlt1, :θlt2], [:x, :y])
  z, θlt1, θlt2, x, y = ⬨(carr)
  θlt1 ⥅ x
  ifelse(z, θlt1 + θlt2, θlt1 - θlt2) ⥅ y
  @assert is_wired_ok(carr)
  foreach(add!(θp), (θlt1, θlt2))
  carr
end

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
