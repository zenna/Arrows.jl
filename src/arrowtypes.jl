"A kind of computation"
abstract Arrow{I,O}

"Each unique arrow has a unique id"
typealias ArrowId Int

## Primitive Arrow
## ===============
"A primitived arrow is a lifted primitive function"
immutable PrimArrow{I, O} <: Arrow{I, O}
  id::ArrowId
  typ::ArrowType
  func::PrimFunc
  PrimArrow(typ::ArrowType, func::PrimFunc) = new{I,O}(genint(),typ,func)
end

inports(a::PrimArrow) = [Port(a, 1, true)]
outports(a::PrimArrow) = [Port(a, 1, false)]
edges(a::PrimArrow) = Dict{Port, Port}()
inner_edges(a::PrimArrow) = edges(a)

# For primitive arrows, flatinports are just imports
flatinports(a::PrimArrow) = inports(a)
flatoutports(a::PrimArrow) = outports(a)

typealias PortId Int

"""A connection point to arrow
 Int is port position.  Bool determines input or output"""
immutable Port
  arr::Arrow
  index::PortId
  inport::Bool
end

## Composite Arrow
## ===============

"A composite arrow composed of simpler (primitive or composite) arrows"
immutable CompositeArrow{I, O} <: Arrow{I,O}
  # typ::ArrowType        # Should be inferrable/consistent with input types
  id::ArrowId
  edges::Dict{Port, Port}
  CompositeArrow() = new{I,O}(genint(),Dict())
  CompositeArrow(edges) = new{I,O}(genint(),edges)
  CompositeArrow(id,edges) = new{I,O}(id,edges)
end

inports{I,O}(a::CompositeArrow{I,O}) = [Port(a, i, true) for i = 1:I]
outports{I,O}(a::CompositeArrow{I,O}) = [Port(a, i, false) for i = 1:O]

"Which port within a composite arrow connects to the outports of the arrow"
function flatinports(a::CompositeArrow)
  ports = Port[]
  for port in inports(a)
    push!(ports, a.edges[port])
  end
  ports
end

"Which port within a composite arrow connects to the outports of the arrow"
function flatoutports(a::CompositeArrow)
  ports = Port[]
  for port in outports(a)
    push!(ports, a.edges[port])
  end
  ports
end

"Is this an inner edge"
isinner_edge(a::CompositeArrow, x::Port, y::Port) = (x.arr != a) && (y.arr != a)

edges(a::CompositeArrow) = a.edges

"All inner edges - i.e. not those which connect to parent ports"
inner_edges(a::CompositeArrow) = filter((k,v)->isinternal(a,k,v), a.edges)

"Add new edges to an arrow"
addedges!(a::CompositeArrow, e::Dict{Port, Port}) = merge!(a.edges, e)

"Make edge from id-th inport of `a` to port"
function link_parent_input!(a::CompositeArrow, id::PortId, port::Port)
  addedges!(a, Dict(Port(a, id, true) => port))
end

"Make edge from id-th inport of `a` to port"
function link_parent_output!(a::CompositeArrow, id::PortId, port::Port)
  addedges!(a, Dict(port => Port(a, id, false)))
end

## List Arrow Type
## =============
"Composite arrow type with arrows stored in graph explicitly"
immutable ListCompositeArrow{I, O} <: Arrow{I,O}
  edges::Dict{PortId, PortId}
  arrows::Vector{Arrow}
end

inports{I,O}(a::ListCompositeArrow{I,O}) = [Port(a, i, true) for i = 1:I]
outports{I,O}(a::ListCompositeArrow{I,O}) = [Port(a, i, false) for i = 1:O]

"Which port within a composite arrow connects to the outports of the arrow"
function flatinports(a::CompositeArrow)
  ports = Port[]
  for port in inports(a)
    push!(ports, a.edges[port])
  end
  ports
end
