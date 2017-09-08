"x + y"
struct AddArrow <: PrimArrow end
name(::AddArrow)::Symbol = :+
port_props(::AddArrow) = bin_arith_port_props()

"x - y"
struct SubtractArrow <: PrimArrow end
name(::SubtractArrow)::Symbol = :-
port_props(::SubtractArrow) = bin_arith_port_props()

"x * y"
struct MulArrow <: PrimArrow end
name(::MulArrow)::Symbol = :*
port_props(::MulArrow) = bin_arith_port_props()

"x / y"
struct DivArrow <: PrimArrow end
name(::DivArrow)::Symbol = :/
port_props(::DivArrow) = bin_arith_port_props()

"exp(x)"
struct ExpArrow <: PrimArrow end
name(::ExpArrow)::Symbol = :exp
port_props(::ExpArrow) = unary_arith_port_props()

"log(x)"
struct LogArrow <: PrimArrow end
name(::LogArrow)::Symbol = :log
port_props(::LogArrow) = unary_arith_port_props()


"sin(x)"
struct SinArrow <: PrimArrow end
name(::SinArrow)::Symbol = :sin
port_props(::SinArrow) = unary_arith_port_props()

"cos(x)"
struct CosArrow <: PrimArrow end
name(::CosArrow)::Symbol = :cos
port_props(::CosArrow) = unary_arith_port_props()

"sqrt(x)"
struct SqrtArrow <: PrimArrow end
name(::SqrtArrow)::Symbol = :sqrt
port_props(::SqrtArrow) = unary_arith_port_props()

"sqr(x)"
struct SqrArrow <: PrimArrow end
name(::SqrArrow)::Symbol = :sqr
port_props(::SqrArrow) = unary_arith_port_props()

sqr(x) = (x^2,)

"log(b, x)"
struct LogBaseArrow <: PrimArrow end
name(::LogBaseArrow)::Symbol = :logbase
port_props(::LogBaseArrow) = unary_arith_port_props()

"-x"
struct NegArrow <: PrimArrow end
name(::NegArrow)::Symbol = :sin
port_props(::NegArrow) = unary_arith_port_props()

"Takes no input simple emits a `value::T`"
struct EqualArrow <: PrimArrow end

name(::EqualArrow) = :(=)
port_props(::EqualArrow) =  [PortProps(true, :x, Array{Real}),
                             PortProps(true, :y, Array{Real}),
                             PortProps(false, :z, Array{Bool})]
