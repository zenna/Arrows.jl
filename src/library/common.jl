function bin_arith_port_props()
  [PortProps(true, :x, Array{Real}),
   PortProps(true, :y, Array{Real}),
   PortProps(false, :z, Array{Real})]
end

function unary_arith_port_props()
  [PortProps(true, :x, Array{Real}),
   PortProps(false, :y, Array{Real})]
end
