function bin_arith_port_attrs()
  [PortAttrs(true, :x, Array{Real}),
   PortAttrs(true, :y, Array{Real}),
   PortAttrs(false, :z, Array{Real})]
end

function unary_arith_port_attrs()
  [PortAttrs(true, :x, Array{Real}),
   PortAttrs(false, :y, Array{Real})]
end
