"""An Arrow of `I` inputs and `O` outputs

Semantics of this model

# `Arrow`
- There are a finite number of primitive arrows, `PrimArrow`
- Each `parr::PrimArrow` is unique and uniquely identifiable by a name, globally
- There are a finite number of composite arrows, `CompArrow`
- Each `CompArrow` is unique and uniquely identifiable by `name(arr)` globally

# `Port`
- An `Arrow` has `I` and `O` input / output ports
- These `I+O` Ports are the `boundary` ports of a `CompArrow`
- `Port`s are named `name(port)` and uniquely identifiable w.r.t. Arrow
- `Port`s on `Arrow` are ordered `1:I+O` but
   ordering is independent of whther is_in_port or is_out_port

# `SubArrow`
- A composite arrow contains a finite number of components: `SubArrow`s
- Each `SubArrow` is unique and uniquely identifiable by name within its parent
- Each `SubArrow` contains a reference to another `PrimArrow` or `CompArrow`
- We can `deref`erence a `SubArrow` to retrieve the `PrimArrow` or `CompArrow`
- A `SubPort` is a port of `SubArrow`
- We can `deref`erence it to get the corresponding port on CompArrow / PrimArrow
- a `SubPort` which is on a `SubArrow` is not a boundary

# `Value`
- All `Port`s that are connected share the same `Value`
- Often it is useful to talk about these `ValueSet` individually
- a `Value` is a set of `Port`s such that there exists an edge between each
  `port ∈ Value`, i.e. a weakly connected component

# `Trace`
- SubArrows can refer to CompArrow's, even the same CompArrow
- In execution and other contexts, it is useful be refer to nested
"""
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