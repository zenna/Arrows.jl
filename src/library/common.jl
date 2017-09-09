function bin_arith_port_props()
  [PortProps(true, :x, Any),
   PortProps(true, :y, Any),
   PortProps(false, :z, Any)]
end

function unary_arith_port_props()
  [PortProps(true, :x, Any),
   PortProps(false, :y, Any)]
end
