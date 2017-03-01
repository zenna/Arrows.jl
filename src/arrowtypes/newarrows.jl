import LightGraphs: Graph, add_edge!, add_vertex!

abstract Arrow{I, O}

immutable Port
  arrow::Arrow
  index::Integer
end

abstract PortAttribute
# immutable Shape <: PortAttribute

abstract PrimArrow

## Composiet Arrows
## ================
"Composite Arrow"
immutable CompArrow{I, O} <: Arrow{I, O}
  name::Symbol
  edges::LightGraphs.Graph  # Each port has a unique index
  port_map::Vector{Port}    # Mapping from port indices in edges to Port
  port_attr::Vector{Set{PortAttribute}}
end

function CompArrow(name::Symbol)
  CompArrow(name, LightGraphs.Graph(), Port[], [])
end

"Find the index of this port in c edges"
function port_index(arr::CompArrow, port::Port)::Integer
  if !is_sub_arrow(arr, port.arrow)
    throw(DomainError())
  else
    res = findfirst(c.port_map, port)
    @assert res > 0
    res
  end
end

function num_all_ports(arr::CompArrow)::Integer
  length(arr.port_map)
end

"Add a port to the composite arrow"
function add_port!(arr::CompArrow)::Port
  push!(arr.port_attr, Set{PortAttribute}())
  p = Port(c, num_all_ports(c))
  push!(arr.port_map, p)
  add_vertex!(arr.edges)
  p
end

"Add an edge in CompArrow from port `l` to port `r`"
function link_ports!(c::CompArrow, l::Port, r::Port)
  l_idx = port_index(c, l)
  r_idx = port_index(c, r)
  add_edge!(c.edges, l_idx, r_idx)
end

## External Interface
function is_sub_arrow(ctx::CompArrow, arrow::Arrow)::Bool
  arrow == ctx || arrow.parent == ctx
end

"How many ports does `arr` have"
function num_ports(arr::CompArrow)::Integer
  return length(arr.port_map)
end

function port(arr::CompArrow, i::Integer)::Port
  if 1 <= i <= num_ports(arr)
    Port(arr, i)
  else
    throw(DomainError())
  end
end

function ports(arr::CompArrow)::Vector{Port}
  [port(arr, i) for i = 1:num_ports(arr)]
end

function out_ports(arr::CompArrow)::Vector{Port}
  filter(p -> is_out_port(p), ports(c))
end

function out_port(arr::CompArrow, i::Integer)::Port
  out_ports(arr)[i]
end


# Example
plus = PrimArrow(:+)
c = CompArrow(:xyx)
p = add_port!(c)
num_ports(c)
port(c, 1)
p2 = add_port!(c)
link_ports!(c, p, p2)
