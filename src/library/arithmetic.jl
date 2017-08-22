"x + y"
struct AddArrow <: PrimArrow{2, 1}
  id::Symbol
end
name(::AddArrow)::Symbol = :+
port_attrs(::AddArrow) = bin_arith_port_attrs()
AddArrow() = AddArrow(gen_id())

"x - y"
struct SubArrow <: PrimArrow{2, 1}
  id::Symbol
end
name(::SubArrow)::Symbol = :-
port_attrs(::SubArrow) = bin_arith_port_attrs()
SubArrow() = SubArrow(gen_id())

"x * y"
struct MulArrow <: PrimArrow{2, 1}
  id::Symbol
end
name(::MulArrow)::Symbol = :*
port_attrs(::MulArrow) = bin_arith_port_attrs()
MulArrow() = MulArrow(gen_id())

"x / y"
struct DivArrow <: PrimArrow{2, 1}
  id::Symbol
end
name(::DivArrow)::Symbol = :/
port_attrs(::DivArrow) = bin_arith_port_attrs()
DivArrow() = DivArrow(gen_id())

"sin(x)"
struct SinArrow <: PrimArrow{1, 1}
  id::Symbol
end
name(::SinArrow)::Symbol = :sin
port_attrs(::SinArrow) = unary_arith_port_attrs()
SinArrow() = SinArrow(gen_id())

"Takes no input simple emits a `value::T`"
struct EqualArrow <: PrimArrow{2, 1}
  id::Symbol
end

name(::EqualArrow) = :(=)
EqualArrow() = EqualArrow(gen_id())
port_attrs(::EqualArrow) =  [PortAttrs(true, :x, Array{Real}),
                             PortAttrs(true, :y, Array{Real}),
                             PortAttrs(false, :z, Array{Bool})]
