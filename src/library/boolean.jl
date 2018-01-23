# Booleans #
const binary_bool_props = [Props(true, :x, Bool),
                           Props(true, :y, Bool),
                           Props(false, :z, Bool)]


"x & y"
struct AndArrow <: PrimArrow end
name(::AndArrow)::Symbol = :(&)
props(::AndArrow) = binary_bool_props

"x | y"
struct OrArrow <: PrimArrow end
name(::OrArrow)::Symbol = :|
props(::OrArrow) = binary_bool_props

"!x"
struct NotArrow <: PrimArrow end
name(::NotArrow)::Symbol = :!
props(::NotArrow) = [Props(true, :x, Bool), Props(false, :y, Bool)]

"x ⊻ y"
struct XorArrow <: PrimArrow end
name(::XorArrow)::Symbol = :⊻
props(::XorArrow) = binary_bool_props
