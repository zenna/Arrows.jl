import LightGraphs: Graph, add_edge!, add_vertex!

## Desiderata
# -Be able to change an undirected arrow to a directed arrow and vice versa
# Be able to make a port an error port or not easily
# be able to maek a port a paraemtric port easily


# FIXME: What about directivity
# FIXME: Should directivity be in teh type?
"An Arrow of `I` inputs and `O` outputs"
abstract Arrow{D, I, O}

## Ports
"""An entry or exit to an Arrow, analogous to argument position of multivariate function.
A port is uniquely determined by the arrow it belongs to and an index"""
abstract Port

immutable OutPort <: Port
  arrow::Arrow
  index::Integer
  labels::Set{Symbol}
end

immutable InPort <: Port
  arrow::Arrow
  index::Integer
  labels::Set{Symbol}
end

"""Port Attributes (i.e) properties intristinc to a port"""
typealias PortAttrs Dict{Symbol, Any}

"Get the port attributes of `port` in arrow `arr`"
port_attrs(port::Port) = port.arrow.port_attrs[port_index(port.arrow, port)]

"Is `port` an `out_port`"
is_out_port(port::Port, port_attrs::PortAttrs)::Bool = :out_port in port_attrs

"Is `port` an `out_port`"
is_out_port(port::Port)::Bool = is_out_port(port, port_attrs(port))

"Is `port` an `in_port`"
is_in_port(port::Port, port_attrs::PortAttrs)::Bool = :in_port in port_attrs

"Is `port` an `in_port`"
is_in_port(port::Port)::Bool = is_in_port(port, port_attrs(port))

"`i`th port of arrow"
function port(arr::Arrow, i::Integer)::Port
  if 1 <= i <= num_ports(arr)
    Port(arr, i)
  else
    throw(DomainError())
  end
end

"all ports of arrow"
ports(arr::Arrow)::Vector{Port} = [port(arr, i) for i = 1:num_ports(arr)]

"out_ports of arr"
function out_ports(arr::Arrow)::Vector{Port}
  collect(filter(p -> is_out_port(p), ports(c)))
end

"`i`th out_port of `arr`"
out_port(arr::Arrow, i::Integer)::Port = out_ports(arr)[i]

"in_ports of arr"
function in_ports(arr::Arrow)::Vector{Port}
  collect(filter(p -> is_in_port(p), ports(arr)))
end

"`i`th in_port of `arr`"
in_port(arr::Arrow, i::Integer)::Port = in_ports(arr)[i]

## Num_ports
"How many ports does `arr` have"
num_ports(arr::Arrow)::Integer = length(arr.port_map)

"How many out ports does `arr` have"
num_out_ports(arr::Arrow)::Integer = length(out_ports(arr))

"How many in ports does `arr` have"
num_in_ports(arr::Arrow)::Integer = length(in_ports(arr))
