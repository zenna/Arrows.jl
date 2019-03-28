"An Arrow of `I` inputs and `O` outputs"
abstract type AbstractArrow end

abstract type Arrow <: AbstractArrow end

abstract type ArrowRef <: AbstractArrow end

## Printing ##
"String for cartesian product of ports"
port_prod(prts; kwargs...) = join([describe(prt; kwargs...) for prt in prts], " × ")

function sig(aarr::AbstractArrow; kwargs...)
  in = port_prod(in_ports(aarr); show_is_in_port = false, show_port_id = false, show_arrow = false, kwargs...)
  out = port_prod(out_ports(aarr); show_is_in_port = false, show_port_id = false, show_arrow = false, kwargs...)
  in * " -> " * out
end

function func_decl(aarr::AbstractArrow; kwargs...)
   string(string(name(aarr)), " : ", sig(aarr; kwargs...))
end

string(aarr::AbstractArrow) = func_decl(aarr)
show(io::IO, aarr::AbstractArrow) = print(io, string(aarr))