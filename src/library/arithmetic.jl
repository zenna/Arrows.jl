"x + y"
struct AddArrow <: PrimArrow{2, 1} end
name(::AddArrow)::Symbol = :+
port_attrs(::AddArrow) = bin_arith_port_attrs()

"x - y"
struct SubtractArrow <: PrimArrow{2, 1} end
name(::SubtractArrow)::Symbol = :-
port_attrs(::SubtractArrow) = bin_arith_port_attrs()

"x * y"
struct MulArrow <: PrimArrow{2, 1} end
name(::MulArrow)::Symbol = :*
port_attrs(::MulArrow) = bin_arith_port_attrs()

"x / y"
struct DivArrow <: PrimArrow{2, 1} end
name(::DivArrow)::Symbol = :/
port_attrs(::DivArrow) = bin_arith_port_attrs()

"exp(x)"
struct ExpArrow <: PrimArrow{1, 1} end
name(::ExpArrow)::Symbol = :sin
port_attrs(::ExpArrow) = unary_arith_port_attrs()

"sin(x)"
struct SinArrow <: PrimArrow{1, 1} end
name(::SinArrow)::Symbol = :sin
port_attrs(::SinArrow) = unary_arith_port_attrs()

"log(b, x)"
struct LogBaseArrow <: PrimArrow{2, 1} end
name(::LogBaseArrow)::Symbol = :logbase
port_attrs(::LogBaseArrow) = unary_arith_port_attrs()

"-x"
struct NegArrow <: PrimArrow{1, 1} end
name(::NegArrow)::Symbol = :sin
port_attrs(::NegArrow) = unary_arith_port_attrs()

"Takes no input simple emits a `value::T`"
struct EqualArrow <: PrimArrow{2, 1} end

name(::EqualArrow) = :(=)
port_attrs(::EqualArrow) =  [PortAttrs(true, :x, Array{Real}),
                             PortAttrs(true, :y, Array{Real}),
                             PortAttrs(false, :z, Array{Bool})]
