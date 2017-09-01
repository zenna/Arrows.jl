"Port Arithmetic"
function binary_arith{T<:Arrow}(x::SubPort, y::SubPort, ArrowType::Type{T})
  c = self_parent(x)
  arr = ArrowType()
  added = add_sub_arr!(arr, c)
  link_ports!(c, x, in_port(added, 1))
  link_ports!(c, y, in_port(added, 2))
  return out_port(added, 1)
end

+(x::Port, y::Port) = binary_arith(x, y, AddArrow)
*(x::Port, y::Port) = binary_arith(x, y, MulArrow)
/(x::Port, y::Port) = binary_arith(x, y, DivArrow)
-(x::Port, y::Port) = binary_arith(x, y, MinusArrow)
