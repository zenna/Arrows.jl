"""An entry or exit to an Arrow, analogous to argument of multivariate function.
A port is uniquely determined by the arrow it belongs to and an index"""
abstract type AbstractPort end

"An interface to an `Arrow`"
struct Port{A <: Arrow, T <: Integer} <: AbstractPort
  arrow::A
  port_id::T
end

"Barebone mechanism to add attributes to a `Port`: it either has label or not"
Label = Symbol

"""Port Properties: properties instrinsic to a port."""
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

"Port properties of `port`"
port_props(prt::Port) = port_props(prt.arrow)[prt.port_id]

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

"out_ports of `aarr`"
out_ports(aarr::AbstractArrow)::Vector{Port} = filter(is_out_port, ports(aarr))

"`i`th out_port of `arr`"
out_port(aarr::AbstractArrow, i::Integer)::Port = out_ports(aarr)[i]

"in_ports of arr"
in_ports(aarr::AbstractArrow)::Vector{Port} = filter(is_in_port, ports(aarr))

"`i`th in_port of `arr`"
in_port(aarr::AbstractArrow, i::Integer)::Port = in_ports(aarr)[i]

## Num_ports ##

"How manny ports does `aarr` have"
num_ports(aarr::AbstractArrow) = length(port_props(aarr))

"How many out ports does `aarr` have"
num_out_ports(aarr::AbstractArrow)::Integer = length(out_ports(aarr))

"How many in ports does `aarr` have"
num_in_ports(aarr::AbstractArrow)::Integer = length(in_ports(aarr))

"Name of `port` where `pa == port_props(port)`"
name(pa::PortProps) = pa.name

"Name of `port`"
name(port::Port) = name(port_props(port))

"Ordered Names of each port of `arr`"
port_names(arr::Arrow) = name.(ports(arr))

## Label ##
"ports in `arr` with label"
function ports(aarr::AbstractArrow, lb::Label)::Vector{Port}
  collect(filter(p -> has_port_label(p, lb), ports(aarr)))AbstractArrow
end

mann(is_in_port::Bool) = is_in_port ? "▸" : "◂"

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
        res *= string(label_to_superscript[label])
      end
    end
  end
  if show_port_id res *= "[$(prt.port_id)]" end
  if show_typ res *= string("::", typ(prt); kwargs...) end
  if show_arrow res *= " on $(name(prt.arrow))" end
  res
end

string(prt::Port) = mann(prt)
print(io::IO, prt::Port) = print(io, string(prt))
show(io::IO, prt::Port) = print(io, prt)
