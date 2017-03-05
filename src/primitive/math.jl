# Primitimve Math Arrow

function bin_arith_port_attrs()
  [PortAttrs(true, :x, Array{Real}),
   PortAttrs(true, :y, Array{Real}),
   PortAttrs(false, :z, Array{Real})]
end

immutable AddArrow <: PrimArrow{2, 1}
  name::Symbol
  port_attrs::Vector{PortAttrs}
  function AddArrow()
    port_attrs = bin_arith_port_attrs()
    new(:+, port_attrs)
  end
end

convert(Arrow, ::typeof(+)) = AddArrow
lift(f::Function) = convert(Arrow, f)
function +(x::Port, y::Port)
  if !same((parent(p) for p in [x,y])
    throw(DomainError())
  end
  # Check all parent arrows are the same
  # Find the corresponding port in this composition
  # Create a new arrow
  # wire them upp


immutable MinusArrow <: PrimArrow{2, 1}
  name::Symbol
  port_attrs::Vector{PortAttrs}
  function AddArrow()
    port_attrs = bin_arith_port_attrs()
    new(:-, port_attrs)
  end
end

immutable MulArrow <: PrimArrow{2, 1}
  name::Symbol
  port_attrs::Vector{PortAttrs}
  function AddArrow()
    port_attrs = bin_arith_port_attrs()
    new(:-, port_attrs)
  end
end

immutable DivArrow <: PrimArrow{2, 1}
  name::Symbol
  port_attrs::Vector{PortAttrs}
  function AddArrow()
    port_attrs = bin_arith_port_attrs()
    new(:/, port_attrs)
  end
end
