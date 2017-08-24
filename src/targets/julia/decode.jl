interpret(::DivArrow, x, y) = (x / y,)
interpret(::MulArrow, x, y) = (x * y,)
interpret(::SubtractArrow, x, y) = (x - y,)
interpret(::AddArrow, x, y) = (x + y,)
interpret(::EqualArrow, x, y) = (x == y,)
interpret(::CondArrow, i, t, e) = ((i ? t : e),)
interpret(arr::SourceArrow) = (arr.value,)
interpret(::IdentityArrow, x) = (x,)
# function interpret(arr::CondArrow, port_map::PortMap)
#   i, t, e = in_ports(arr)
#   port_map[i] ? port_map[t] : port_map[e]
# end
