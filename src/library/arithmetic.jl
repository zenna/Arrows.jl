"x + y"
struct AddArrow <: PrimArrow{2, 1} end
name(::AddArrow)::Symbol = :+
port_props(::AddArrow) = bin_arith_port_props()

"x - y"
struct SubtractArrow <: PrimArrow{2, 1} end
name(::SubtractArrow)::Symbol = :-
port_props(::SubtractArrow) = bin_arith_port_props()

"x * y"
struct MulArrow <: PrimArrow{2, 1} end
name(::MulArrow)::Symbol = :*
port_props(::MulArrow) = bin_arith_port_props()

"x / y"
struct DivArrow <: PrimArrow{2, 1} end
name(::DivArrow)::Symbol = :/
port_props(::DivArrow) = bin_arith_port_props()

"exp(x)"
struct ExpArrow <: PrimArrow{1, 1} end
name(::ExpArrow)::Symbol = :sin
port_props(::ExpArrow) = unary_arith_port_props()

"sin(x)"
struct SinArrow <: PrimArrow{1, 1} end
name(::SinArrow)::Symbol = :sin
port_props(::SinArrow) = unary_arith_port_props()

"log(b, x)"
struct LogBaseArrow <: PrimArrow{2, 1} end
name(::LogBaseArrow)::Symbol = :logbase
port_props(::LogBaseArrow) = unary_arith_port_props()

"-x"
struct NegArrow <: PrimArrow{1, 1} end
name(::NegArrow)::Symbol = :sin
port_props(::NegArrow) = unary_arith_port_props()

"Takes no input simple emits a `value::T`"
struct EqualArrow <: PrimArrow{2, 1} end

name(::EqualArrow) = :(=)
port_props(::EqualArrow) =  [PortProps(true, :x, Array{Real}),
                             PortProps(true, :y, Array{Real}),
                             PortProps(false, :z, Array{Bool})]
