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
