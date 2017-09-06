"""An entry or exit to an Arrow, analogous to argument of multivariate function.
A port is uniquely determined by the arrow it belongs to and an index"""
abstract type AbstractPort end

struct Port{A <: Arrow, T <: Integer} <: AbstractPort
  arrow::A
  port_id::T
end

"Is `port` a reference?"
is_ref(port::Port) = false

"""port properties: properties instrinsic to a port.

- `PortProp`s are a property of an Arrow or SubtractArrow
"""
mutable struct PortProps
  is_in_port::Bool
  name::Symbol
  typ::Type
end

"Does a vector of port properties have I inports and O outports?"
function is_valid(port_props::Vector{PortProps}, I::Integer, O::Integer)::Bool
  ni = 0
  no = 0
  for port_prop in port_props
    if is_in_port(port_prop)
      ni += 1
    elseif is_out_port(port_prop)
      no += 1
    end
  end
  ni == I && no == O
end

"Get the port properties of `port` in arrow `arr`"
port_props(port::Port) = port_props(port.arrow)[port.port_id]

"Is `port` an `out_port`"
is_out_port(port_props::PortProps)::Bool = !port_props.is_in_port

"Is `port` an `out_port`"
is_out_port(port::AbstractPort)::Bool = is_out_port(port_props(port))

"Is `port` an `in_port`"
is_in_port(port_props::PortProps)::Bool = port_props.is_in_port

"Is `port` an `in_port`"
is_in_port(port::AbstractPort)::Bool = is_in_port(port_props(port))

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
# num_ports(arr::AbstractArrow)::Integer = length(ports(arr))
num_ports(arr::AbstractArrow) = length(port_props(arr))

"How many out ports does `arr` have"
num_out_ports(arr::AbstractArrow)::Integer = length(out_ports(arr))

"How many in ports does `arr` have"
num_in_ports(arr::AbstractArrow)::Integer = length(in_ports(arr))

name(pa::PortProps) = pa.name
name(port::Port) = name(port_props(port))

"Names of each port of `arr`"
port_names(arr::Arrow) = name.(ports(arr))

function string(p::Port)
  inps = is_in_port(p) ? "InPort" : "OutPort"
  pa = port_props(p)
  "$inps id:$(p.port_id) n:$(pa.name) arr:$(name(p.arrow))"
end

print(io::IO, p::Port) = print(io, string(p))
show(io::IO, p::Port) = print(io, p)
