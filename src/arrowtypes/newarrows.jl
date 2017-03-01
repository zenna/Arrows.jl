import LightGraphs

abstract Arrow

immutable Port
  arrow::Arrow
  index::Integer
end

abstract PortAttribute
immutable Shape <: PortAttribute
immutable PrimitiveArrow <: Arrow
  name::String
end

immutable CompositeArrow <: Arrow
  name::String
  edges::LightGraphs.Graph  # Each port has a unique index
  ports::Vector{Port}
  port_attr::Vector{Set{PortAttribute}}
end

function is_sub_arrow(ctx::CompositeArrow, arrow::Arrow)::Bool
  arrow == ctx || arrow.parent == ctx
end

function port_index(ctx::CompositeArrow, port::Port)::Integer
  if arr.parent != context
    throw(DomainError())
  else
end

function add_port!(c::CompositeArrow)::Port
  push!(c.port_attr, Set{PortAttribute}())
  Port(c, num_ports(c))
end

"""How many ports does `arr` have"""
function num_ports(arr::CompositeArrow)::Integer
  return length(arr.port_attr)
end

function ports(arr::CompositeArrow)::Vector{Port}
  [Port(arr, i) for i = 1:num_prts(arr)]
end

function out_ports(c::CompositeArrow)::
  filter(p -> is_out_port(p), ports(c))
end

function out_port(c::CompositeArrow, i::Integer)
  out_ports(c)[i]
end


function add_edge(l::Port, r::Port)
  1 + 1
end

# Example
plus = PrimitiveArrow("plus")
c = CompositeArrow("name", LightGraphs.Graph(), [])
out_port(c, 0)


## Predicate Dispatch

@defmulti foo ok
@defmethod
