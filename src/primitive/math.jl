"Primitive Math Arrow"

function bin_arith_port_attrs()
  [PortAttrs(true, :x, Array{Real}),
   PortAttrs(true, :y, Array{Real}),
   PortAttrs(false, :z, Array{Real})]
end

set_parent!{A <: PrimArrow}(arr::A, c_arr::CompArrow)::A = A(c_arr)

struct AddArrow <: PrimArrow{2, 1}
  id::Symbol
  parent::Nullable{CompArrow}
end
name(::AddArrow)::Symbol = :+
port_attrs(::AddArrow) = bin_arith_port_attrs()
AddArrow() = AddArrow(gen_id(), Nullable{CompArrow}())
AddArrow(parent::CompArrow) = AddArrow(gen_id(), parent)

struct SubArrow <: PrimArrow{2, 1}
  id::Symbol
  parent::Nullable{CompArrow}
end
name(::SubArrow)::Symbol = :-
port_attrs(::SubArrow) = bin_arith_port_attrs()
SubArrow() = SubArrow(gen_id(), Nullable{CompArrow}())
SubArrow(parent::CompArrow) = AddArrow(gen_id(), parent)

struct MulArrow <: PrimArrow{2, 1}
  id::Symbol
  parent::Nullable{CompArrow}
end
name(::MulArrow)::Symbol = :*
port_attrs(::MulArrow) = bin_arith_port_attrs()
MulArrow() = MulArrow(gen_id(), Nullable{CompArrow}())
MulArrow(parent::CompArrow) = MulArrow(gen_id(), parent)

struct DivArrow <: PrimArrow{2, 1}
  id::Symbol
  parent::Nullable{CompArrow}
end
name(::DivArrow)::Symbol = :/
port_attrs(::DivArrow) = bin_arith_port_attrs()
DivArrow() = DivArrow(gen_id(), Nullable{CompArrow}())
DivArrow(parent::CompArrow) = DivArrow(gen_id(), parent)

function unary_arith_port_attrs()
  [PortAttrs(true, :x, Array{Real}),
   PortAttrs(false, :y, Array{Real})]
end

struct SinArrow <: PrimArrow{1, 1}
  id::Symbol
  parent::Nullable{CompArrow}
end
name(::SinArrow)::Symbol = :sin
port_attrs(::SinArrow) = unary_arith_port_attrs()
SinArrow() = SinArrow(gen_id(), Nullable{CompArrow}())
SinArrow(parent::CompArrow) = SinArrow(gen_id(), parent)

"Takes no input simple emits a `value::T`"
struct SourceArrow{T} <: PrimArrow{0, 1}
  id::Symbol
  value::T
end

name(::SourceArrow) = :source
SourceArrow{T}(value::T) = SourceArrow(gen_id(), value)
port_attrs{T}(::SourceArrow{T}) =  [PortAttrs(false, :x, Array{T})]

"Takes no input simple emits a `value::T`"
struct EqualArrow <: PrimArrow{2, 1}
  id::Symbol
end

name(::EqualArrow) = :(=)
EqualArrow() = EqualArrow(gen_id())
port_attrs(::EqualArrow) =  [PortAttrs(true, :x, Array{Real}),
                             PortAttrs(true, :y, Array{Real}),
                             PortAttrs(false, :z, Array{Bool})]

"Takes no input simple emits a `value::T`"
struct CondArrow <: PrimArrow{3, 1}
  id::Symbol
end

port_attrs(::CondArrow) =   [PortAttrs(true, :i, Array{Bool}),
                             PortAttrs(true, :t, Array{Real}),
                             PortAttrs(true, :e, Array{Real}),
                             PortAttrs(false, :e, Array{Real})]
name(::CondArrow) = :cond
CondArrow() = CondArrow(gen_id())


# DuplArrow
"Duplicates input `I` times dupl_n_(x) = (x,...x)"
struct DuplArrow{I} <: PrimArrow{I, 1}
  id::Symbol
  function DuplArrow{I}(n::Integer, id::Symbol) where {I}
    new{n}(id)
  end
end

port_attrs{I}(::DuplArrow{I}) =
  [PortAttrs(true, :x, Array{Any}),
   [PortAttrs(false, Symbol(:y, i), Array{Any}) for i=1:I]...]

name(::DuplArrow) = :dupl
DuplArrow(n::Integer) = DuplArrow{n}(n, gen_id())

# convert(Arrow, ::typeof(+)) = AddArrow
# lift(f::Function) = convert(Arrow, f)
# function +(x::Port, y::Port)
#   # Check all parent arrows are the same
#   if !same((parent(p) for p in [x,y]))
#     throw(DomainError())
#   end
#
#   # Find the corresponding port in this composition
#   x2 = proj_port(x)
#   y2 = proj_port(y)
#
#   addarr = AddArrow()
#   # Create a new arrow
#   # wire them upp
# end
