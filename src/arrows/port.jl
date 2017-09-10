"""An entry or exit to an Arrow, analogous to argument of multivariate function.
A port is uniquely determined by the arrow it belongs to and an index"""
abstract type AbstractPort end

struct Port{A <: Arrow, T <: Integer} <: AbstractPort
  arrow::A
  port_id::T
end

"Is `port` a reference?"
is_ref(port::Port) = false

Label = Symbol


"""port properties: properties instrinsic to a port.

- `PortProp`s are a property of an Arrow or SubtractArrow
"""
mutable struct PortProps
  is_in_port::Bool
  name::Symbol
  typ::Type
  labels::Set{Label}
end

"Make a copy of `PortProps`, assign partial fields"
function PortProps(pprops;
                   is_in_port::Bool = pprops.is_in_port,
                   name::Symbol = pprops.name,
                   typ::Type = pprops.typ,
                   labels::Set{Label} = pprops.labels)
  deepcopy(PortProps(is_in_port, name, typ, labels))
end

PortProps(is_in_port, name, typ) = PortProps(is_in_port, name, typ, Set())

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

"Type of port"
typ(pprops::PortProps) = pprops.typ

"Is `port` an `in_port`"
is_in_port(port::AbstractPort)::Bool = is_in_port(port_props(port))

"labels of `aport`, e.g. `:parametric, :error`"
labels(aport::AbstractPort) = labels(port_props(aport))

"Type of a `aport`"
typ(aport::AbstractPort) = typ(port_props(aport))

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
"How manny ports does `arr` have"
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

## Label ##
"out_ports of arr"
function ports(arr::Arrow, lb::Label)::Vector{<:AbstractPort}
  collect(filter(p -> has_port_label(p, lb), ports(arr)))
end

"Does `port` have `label` `lb`?"
has_port_label(port::Port, lb::Label) = lb ∈ port_props(port).labels

"Make `prop` parameter"
function set_error_port!(pprop::PortProps)
  is_out_port(pprop) || throw(DomainError())
  push!(pprop.labels, :error)
end
is_error_port(pprop::PortProps) = :error ∈ pprop.labels
is_error_port(port::Port) = is_error_port(port_props(port))
set_error_port!(port::Port) = set_error_port!(port_props(port))

"Make `prop` parameter"
function set_parameter_port!(pprop::PortProps)
  is_in_port(pprop) || throw(DomainError())
  push!(pprop.labels, :parameter)
end

is_parameter_port(pprop::PortProps) = :parameter ∈ pprop.labels
is_parameter_port(port::Port) = is_parameter_port(port_props(port))
set_parameter_port!(port::Port) = set_parameter_port!(port_props(port))

mann(is_in_port::Bool) = is_in_port ? "🡪" : "🡨"

## Printing ##
const label_to_superscript = Dict{Symbol, Symbol}(
  :parameter => :ᶿ,
  :error => :ᵋ)

function mann(prt::Port; show_name=true,
                         show_port_id=true,
                         show_is_in_port=true,
                         show_typ=true,
                         show_arrow=true,
                         show_labels=true,
                         kwargs...)
  res = ""
  if show_is_in_port res *= mann(is_in_port(prt)) end
  if show_name
    res *= string(name(prt))
    if show_labels
      for label in port_props(prt).labels
        @show res
        res *= string(label_to_superscript[label])
      end
    end
  end
  if show_port_id res *= "@$(prt.port_id)" end
  if show_typ res *= string("::", typ(prt); kwargs...) end
  res
end

string(prt::Port) = mann(prt)
print(io::IO, prt::Port) = print(io, string(prt))
show(io::IO, prt::Port) = print(io, prt)
