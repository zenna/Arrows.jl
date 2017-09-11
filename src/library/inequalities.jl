# Order alphabetically
const ineq_port_props = [PortProps(true, :x, Real),
                         PortProps(true, :y, Real),
                         PortProps(false, :z, Bool)]

# Inequalities #

"x > y"
struct GreaterThanArrow <: PrimArrow end
name(::GreaterThanArrow)::Symbol = :>
port_props(::GreaterThanArrow) = ineq_port_props

"x >= y"
struct GreaterThanEqualArrow <: PrimArrow end
name(::GreaterThanEqualArrow)::Symbol = :(>=)
port_props(::GreaterThanEqualArrow) = ineq_port_props

"x <= y"
struct LessThanEqualArrow <: PrimArrow end
name(::LessThanEqualArrow)::Symbol = :(<=)
port_props(::LessThanEqualArrow) = ineq_port_props

"x < y"
struct LessThanArrow <: PrimArrow end
name(::LessThanArrow)::Symbol = :(<)
port_props(::LessThanArrow) = ineq_port_props

# Equality #

"Takes no input simple emits a `value::T`"
struct EqualArrow <: PrimArrow end
name(::EqualArrow) = :(==)
port_props(::EqualArrow) = ineq_port_props
