"""An entry or exit to an Arrow, analogous to argument of multivariate function.
A port is uniquely determined by the arrow it belongs to and an index"""
abstract type AbstractPort end

struct Port{A <: Arrow, T <: Integer} <: AbstractPort
  arrow::A
  index::T
end

"Is `port` a reference?"
is_ref(port::Port) = false

# "A reference to a `Port`"
# SubPort{A, T} = Port{A, T} where A <: ArrowRef
# SubPort{A, T} = Port{A, T} # A SubPort is a Port whose `arrow` is ArrowRef

# "Is `port` a reference?"
# is_ref{A}(port::Port{A}) = A <: ArrowRef

"""Port Attributes: properties instrinsic to a port.

- `PortAttr`s are a property of an Arrow or SubtractArrow
"""
struct PortAttrs
  is_in_port::Bool
  name::Symbol
  typ::Type
end


"Does a vector of port attributes have I inports and O outports?"
function is_valid(port_attrs::Vector{PortAttrs}, I::Integer, O::Integer)::Bool
  ni = 0
  no = 0
  for port_attr in port_attrs
    if is_in_port(port_attr)
      ni += 1
    elseif is_out_port(port_attr)
      no += 1
    end
  end
  ni == I && no == O
end

"Get the port attributes of `port` in arrow `arr`"
port_attrs(port::Port) = port_attrs(port.arrow)[port.index]

"Is `port` an `out_port`"
is_out_port(port_attrs::PortAttrs)::Bool = !port_attrs.is_in_port

"Is `port` an `out_port`"
is_out_port(port::AbstractPort)::Bool = is_out_port(port_attrs(port))

"Is `port` an `in_port`"
is_in_port(port_attrs::PortAttrs)::Bool = port_attrs.is_in_port

"Is `port` an `in_port`"
is_in_port(port::AbstractPort)::Bool = is_in_port(port_attrs(port))

"`i`th port of arrow"
function port(arr::Arrow, i::Integer)::Port
  if 1 <= i <= num_ports(arr)
    Port(arr, i)
  else
    throw(DomainError())
  end
end

"all ports of arrow"
ports(arr::Arrow)::Vector{Port} = [Port(arr, i) for i = 1:num_ports(arr)]

"out_ports of arr"
function out_ports(arr::Arrow)::Vector{<:AbstractPort}
  collect(filter(p -> is_out_port(p), ports(arr)))
end

"`i`th out_port of `arr`"
out_port(arr::Arrow, i::Integer)::AbstractPort = out_ports(arr)[i]

"in_ports of arr"
function in_ports(arr::Arrow)::Vector{<:AbstractPort}
  collect(filter(p -> is_in_port(p), ports(arr)))
end

"`i`th in_port of `arr`"
in_port(arr::Arrow, i::Integer)::AbstractPort = in_ports(arr)[i]

## Num_ports
"How many ports does `arr` have"
num_ports{I, O}(arr::Arrow{I, O})::Integer = I + O

"How many out ports does `arr` have"
num_out_ports{I, O}(arr::Arrow{I, O})::Integer = O

"How many in ports does `arr` have"
num_in_ports{I, O}(arr::Arrow{I, O})::Integer = I

function string(p::Port)
  inps = is_in_port(p) ? "InPort" : "OutPort"
  pa = port_attrs(p)
  "$inps id:$(p.index) n:$(pa.name) arr:$(name(p.arrow))"
end

print(io::IO, p::Port) = print(io, string(p))
show(io::IO, p::Port) = print(io, p)
