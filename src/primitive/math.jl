function bin_arith_port_attrs()
  [PortAttrs(true, :x, Array{Real}),
   PortAttrs(true, :y, Array{Real}),
   PortAttrs(false, :z, Array{Real})]
end

set_parent!{A <: PrimArrow}(arr::A, c_arr::CompArrow)::A = A(c_arr)

immutable AddArrow <: PrimArrow{2, 1}
  id::Symbol
  parent::Nullable{CompArrow}
end
name(::AddArrow)::Symbol = :+
port_attrs(::AddArrow) = bin_arith_port_attrs()
AddArrow() = AddArrow(gen_id(), Nullable{CompArrow}())
AddArrow(parent::CompArrow) = AddArrow(gen_id(), parent)

function unary_arith_port_attrs()
  [PortAttrs(true, :x, Array{Real}),
   PortAttrs(false, :y, Array{Real})]
end

immutable SinArrow <: PrimArrow{1, 1}
  id::Symbol
  parent::Nullable{CompArrow}
end
name(::SinArrow)::Symbol = :sin
port_attrs(::SinArrow) = unary_arith_port_attrs()
SinArrow() = SinArrow(gen_id(), Nullable{CompArrow}())
SinArrow(parent::CompArrow) = SinArrow(gen_id(), parent)

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
