"A functional unit which transforms `I` input to `O` outputs"
abstract Arrow{I, O}

## Port
## ====
# Smaller precision might suffice
typealias ArrowId Int
typealias PinId Int

"""A port is uniquely determined by the arrow it belongs to and a pin.
  By convention, a port which is on the parnt arrow will have `arrow = 1.
  Pin ids are contingous from `1:I+O`, with the input taking the first `1:I`"""
immutable Port
  arrow::ArrowId
  pin::PinId
end

"Is this an input port, ports are ordered with input pins taking first integers"
isinputport{I,O}(p::Port, a::Arrow{I,O}) = p.pin <= I

"Is this port on the boundary"
isboundary(p::Port) = p.arrow == 1

## Generic Arrow
## ==============

inports{I,O}(a::Arrow{I, O}) = Port[Port(1, i) for i = 1:I]
outports{I,O}(a::Arrow{I, O}) = Port[Port(1, i) for i = I+1:I+O]
ports(a::Arrow) = vcat(inports(a), outports(a))::Vector{Port}

ninports{I,O}(a::Arrow{I,O}) = I
noutports{I,O}(a::Arrow{I,O}) = O
nports{I,O}(a::Arrow{I,O}) = I + O

## Primitive Arrow
## ===============
"A primitived arrow is a lifted primitive function"
immutable PrimArrow{I, O} <: Arrow{I, O}
  typ::ArrowType
  func::PrimFunc
end

"number of arrows"
nnodes(a::PrimArrow) = 1
nodes(a::PrimArrow) = Arrow[a]

# Primitive arrows have no edges
edges(a::PrimArrow) = Dict{Port, Port}()

"An arrow with `I` input ports and `O` output ports"
immutable CompositeArrow{I, O} <: Arrow{I,O}
  edges::Dict{Port, Port}
  nodes::Vector{Arrow}
  CompositeArrow() = new{I,O}(Dict{Port, Port}(), Arrow[])
end

addnodes!{T<:Arrow}(c::CompositeArrow, nodes::Vector{T}) = push!(c.nodes, nodes...)
nodes(a::CompositeArrow) = a.nodes
nnodes(a::CompositeArrow) = length(nodes(a))

edges(a::CompositeArrow) = a.edges
addedges!(a::CompositeArrow, e::Dict{Port, Port}) = merge!(a.edges, e)
addedge!(a::CompositeArrow, p1::Port, p2::Port) = a.edges[p1] = p2

"Pinid w.r.t first input (output) pin, e.g. return 1 if first input (output) pin"
relativepinid{I,O}(a::Arrow{I,O}, pin::PinId) = pin > I ? pin - I : pin

function shift{I,O}(p::Port, a::CompositeArrow{I,O})
  # if it's a boundary pin shift it depending on whether its an input or output
  #FIXME< this is a weird function
  if isboundary(p)
    # @show p.pin
    # @show iopinid(a, p.pin)
    isinputport(p, a) ? Port(p.arrow,p.pin + I) : Port(p.arrow, relativepinid(a, p.pin)+I)
  else
    Port(p.arrow + nnodes(a), p.pin)
  end
end

"Wrap primitive arrow in composite arrow - behaves identically to original arrow"
function encapsulate{I,O}(a::PrimArrow{I,O})
  c = CompositeArrow{I,O}()
  addnodes!(c, [a])
  for i = 1:I
    addedge!(c, Port(1, i), Port(2, i))
  end

  for i = I+1:I+O
    addedge!(c, Port(2, i), Port(1, i))
  end
  c
end

"Return the ports of the arrow with `arrid` inside `a`"
function subarrowports(a::CompositeArrow, arrid::ArrowId)
  # The self arrow
  if arrid == 1
    @show ports(a)
  else
    subarr = nodes(a)[arrid-1]
    @show [Port(arrid, p) for p = 1:nports(subarr)]
  end
end

"Return all the ports of a composite arrow, including subarrows"
function allports(a::CompositeArrow)
  theports = Port[]
  for i = 1:nnodes(a)+1
    push!(theports, subarrowports(a, i)...)
  end
  @show theports
end

"Is this arrow well formed? Are all its ports (and no others) connected?"
function iswellformed{I,O}(c::CompositeArrow{I,O})
  alltheports = Set{Port}(allports(c))
  for (p1, p2) in edges(c)
    if (p1 in alltheports) && (p2 in alltheports)
      delete!(alltheports, p1)
      delete!(alltheports, p2)
    else
      # error("arrow not well formed")
      return false
    end
  end

  if isempty(alltheports)
    return true
  else
    # end"some unconnected ports"
    return false
  end
end
