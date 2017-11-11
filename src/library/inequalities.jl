# Order alphabetically
const ineq_props = [Props(true, :x, Real),
                         Props(true, :y, Real),
                         Props(false, :z, Bool)]

# Inequalities #

"x > y"
struct GreaterThanArrow <: PrimArrow end
name(::GreaterThanArrow)::Symbol = :>
props(::GreaterThanArrow) = ineq_props

"x >= y"
struct GreaterThanEqualArrow <: PrimArrow end
name(::GreaterThanEqualArrow)::Symbol = :(>=)
props(::GreaterThanEqualArrow) = ineq_props

"x <= y"
struct LessThanEqualArrow <: PrimArrow end
name(::LessThanEqualArrow)::Symbol = :(<=)
props(::LessThanEqualArrow) = ineq_props

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
