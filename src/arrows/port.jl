"""
An entry or exit to an Arrow, analogous to argument of multivariate function.
A port is uniquely determined by the arrow it belongs to and an index
"""
abstract type AbstractPort end

"An interface to an `Arrow`"
struct Port{A <: Arrow} <: AbstractPort
  arrow::A
  port_id::Int
end

port_id(prt::Port) = prt.port_id

"Port properties of `port`"
props(prt::AbstractPort) = props(prt.arrow)[prt.port_id]
labels(prt::AbstractPort) = labels(props(prt))
addprop!(T::Type{<:Prop}, prt::AbstractPort) = (addprop!(T, props(prt)); prt)
in(P::Type{<:Prop}, prt::AbstractPort) = in(P, props(prt))

"Transfer labels from `prta` to `prtb`"
function transferlabels!(prta::Port, prtb::Port) # FIXME: define in terms of props first
  for label in labels(prta)
    push!(props(prtb).labels, label)
  end
end

"Is `port` an `out_port`"
is_out_port(prt::AbstractPort)::Bool = isout(props(prt))

"Is `port` an `out_port`"
is_in_port(prt::AbstractPort)::Bool = isin(props(prt))

"Type of `aport`"
typ(aprt::AbstractPort) = typ(props(aprt))

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

# FIXME: Deprecate
"out_ports of `aarr`"
out_ports(aarr::AbstractArrow)::Vector{Port} = filter(is_out_port, ports(aarr))

# FIXME: Deprecate
"`i`th out_port of `arr`"
out_port(aarr::AbstractArrow, i::Integer)::Port = out_ports(aarr)[i]

# FIXME: Deprecate
"in_ports of arr"
in_ports(aarr::AbstractArrow)::Vector{Port} = filter(is_in_port, ports(aarr))

# FIXME: Deprecate
"`i`th in_port of `arr`"
in_port(aarr::AbstractArrow, i::Integer)::Port = in_ports(aarr)[i]

## Num_ports ##

# FIXME: Deprecate
"How many ports does `aarr` have"
num_ports(aarr::AbstractArrow) = length(props(aarr))

# FIXME: Deprecate
"How many out ports does `aarr` have"
num_out_ports(aarr::AbstractArrow)::Integer = length(out_ports(aarr))

# FIXME: Deprecate
"How many in ports does `aarr` have"
num_in_ports(aarr::AbstractArrow)::Integer = length(in_ports(aarr))

"Name of `port`"
name(port::Port) = name(props(port))

"Symbol name of `prt`"
port_sym_name(prt::Port) = name(prt).name

"Position of `prt` in out_ports of its arrow"
pos_in_out_ports(prt::Port) = findfirst(◂(prt.arrow), prt)

"Position of prt in its in ports of its arrow"
pos_in_in_ports(prt::Port) = findfirst(▸(prt.arrow), prt)

# FIXME: Unecessary functions, deprecate / Move these elsewhere
port_sym_names(arr::Arrow) = port_sym_name.(ports(arr))
in_port_sym_names(arr::Arrow) = port_sym_name.(in_ports(arr))
out_port_sym_names(arr::Arrow) = port_sym_name.(out_ports(arr))

## Label ##
describe(is_in_port::Bool) = is_in_port ? "▹" : "◃"

## Printing ##
"Describe `prt` (as string) with variable options"
function describe(prt::Port; show_name=true,
                             show_port_id=true,
                             show_is_in_port=true,
                             show_typ=true,
                             show_arrow=true,
                             show_labels=true,
                             kwargs...)
  res = ""
  if show_is_in_port res *= describe(is_in_port(prt)) end
  if show_name
    res *= string(name(prt))
    if show_labels
      for label in map(superscript, labels(prt))
        res *= string(label)
      end
    end
  end
  if show_typ res *= string("::", string(typ(prt)); kwargs...) end
  if show_arrow res *= " on $(name(prt.arrow))" end
  if show_port_id res *= "[$(prt.port_id)]" end
  res
end

string(prt::Port) = describe(prt)
show(io::IO, prt::Port) = print(io, string(prt))
