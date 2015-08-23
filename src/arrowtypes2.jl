abstract Arrow{I, O}

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

## Primitive Arrow
## ===============
"A primitived arrow is a lifted primitive function"
immutable PrimArrow{I, O} <: Arrow{I, O}
  typ::ArrowType
  func::PrimFunc
end

"number of sub arrows"
nsubarrows(a::PrimArrow) = 1
  nodes(a::PrimArrow) = Arrow[a]
edges(a::PrimArrow) = Dict{Port, Port}()
inneredges(a::PrimArrow) = Dict{Port, Port}()
inports{I,O}(a::PrimArrow{I, O}) = [Port(1, i) for i = 1:I]
outports{I,O}(a::PrimArrow{I, O}) = [Port(1, i) for i = I+1:I+O]

# These only make sense in the context of composite ports
ingateports(a::PrimArrow) = inports(a)
outgateports(a::PrimArrow) = outports(a)

"An arrow with `I` input ports and `O` output ports"
immutable CompositeArrow{I, O} <: Arrow{I,O}
  edges::Dict{Port, Port}
  nodes::Vector{Arrow}
  CompositeArrow() = new{I,O}(Dict{Port, Port}(), Arrow[])
end

addnodes!{T<:Arrow}(c::CompositeArrow, nodes::Vector{T}) = push!(c.nodes, nodes...)
nodes(a::CompositeArrow) = a.nodes
nsubarrows(a::CompositeArrow) = length(nodes(a))

"Number of inner ports"
nports(a::CompositeArrow) = length(a.nodes)
# FIXME: Dry
inports{I,O}(a::CompositeArrow{I, O}) = [Port(1, i) for i = 1:I]
outports{I,O}(a::CompositeArrow{I, O}) = [Port(1, i) for i = I+1:I+O]

ingateedges(a::CompositeArrow) = [Port(1, i) => a.edges(Port(1,i))  for i = 1:I]
outgateedges(a::CompositeArrow) =
  filter((p1, p2) -> (p2.arrow == 1), a.edges)

ingateports{I,O}(a::CompositeArrow{I,O}) = [a.edges[Port(a, i)] for i = 1:I]
function outgateports{I,O}(a::CompositeArrow{I,O})
  outs = Dict{Int, Port}()
  for (p1, p2) in edges(a)
    if isboundary(p2)
      outs[p2.pin] = p1
    end
  end
  Port[outs[i] for i = 1:O]
end

edges(a::CompositeArrow) = a.edges
addedges!(a::CompositeArrow, e::Dict{Port, Port}) = merge!(a.edges, e)
addedge!(a::CompositeArrow, p1::Port, p2::Port) = a.edges[p1] = p2
inneredges(a::CompositeArrow) =
  filter((p1, p2) -> (p1.arrow != 1) && (p2.arrow != 1), a.edges)

# function shift_edges(e::Dict{Port,Port}, shift::Integer)
#   [Port(p1.arrow + shift, p1.pin) => Port(p2.arrow + shift, p2.pin) for (p1, p2) in e]
# end
#
# function left_shift_edges(e::Dict{Port,Port}, shift::Integer)
#   [Port(p1.arrow + shift, p1.pin) => Port(p2.arrow, p2.pin) for (p1, p2) in e]
# end
#
# function right_shift_edges(e::Dict{Port,Port}, shift::Integer)
#   [Port(p1.arrow, p1.pin) => Port(p2.arrow + shift, p2.pin) for (p1, p2) in e]
# end
#
# ## Drawing
# ##
#
## combinators
"Lifts a primitive function to an arrow"
lift{I,O}(a::PrimFunc{I,O}) = PrimArrow{I,O}(a.typ, a)
#
# ">>> Mulitary Forward Arrow composition"
# function compose{I1, O1I2, O2}(a::Arrow{I1,O1I2}, b::Arrow{O1I2,O2})
#   c = CompositeArrow{I1,O2}()
#   addnodes!(c, nodes(a))
#   addnodes!(c, nodes(b))
#
#   shift = nsubarrows(a)
#   ## Add inner edges from a and b (where they exist)
#   addedges!(c, inneredges(a))
#   addedges!(c, shift_edges(inneredges(b), shift))
#
#   # Add edges that connect inputs to a and b to outputs
#   addedges!(c, Dict(zip(inports(c), ingateports(a))))
#   addedges!(c, left_shift_edges(Dict(zip(outgateports(b), outports(c))), shift))
#
#   # Now connect output of a to input of b
#   out_a = outgateports(a)
#   in_b = ingateports(b)
#   @assert length(out_a) == length(in_b)
#   addedges!(c, right_shift_edges(Dict(zip(out_a, in_b)), shift))
#   c
# end

function outputn{I,O}(a::Arrow{I,O}, pin::PinId)
  @assert pin > I "pinid $pin not an output pin on arrow{$I, $O}"
  pin - I
end

function shift{I,O}(p::Port, a::CompositeArrow{I,O})
  # if it's a boundary pin shift it depending on whether its an input or output
  #FIXME< this is a weird function
  if isboundary(p)
    @show p.pin
    @show outputn(a, p.pin)
    isinputport(p, a) ? Port(p.arrow,p.pin + I) : Port(p.arrow, outputn(a, p.pin)+I)
  else
    Port(p.arrow + nsubarrows(a), p.pin)
  end
end

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

function compose{I1, O1I2, O2}(a::CompositeArrow{I1,O1I2}, b::CompositeArrow{O1I2,O2})
  c = CompositeArrow{I1,O2}()
  addnodes!(c, nodes(a))
  addnodes!(c, nodes(b))
  @show c
  @show nodes(a)
  @show nodes(b)

  new_edges = Dict{Port, Port}()
  for (p1, p2) in edges(a)
    @show p1, p2
    # if p2 is an output boundary and p1 not input boundary
    # if p1 is an input boundary and p2 is output |---------------|
    # |     |*****|-----------|
    if isboundary(p2)
      p3 = b.edges[Port(1,outputn(a, p2.pin))]
      addedge!(c, p1, shift(p3, a))

    # inner edge
    # |------|*****|        |
    # |        |*****|------|*****|        |
    else
      addedge!(c, p1, p2)
    end
  end

  println("outputs\n")

  for (p1, p2) in edges(b)
    if !isboundary(p1)
      # Shift
      @show p1, p2
      @show shift(p1, a)
      @show shift(p2, a)
      addedge!(c, shift(p1, a), shift(p2, a))
    end
  end
  check(c)
end

function subinports(a::CompositeArrow, i::ArrowId)
  #assert b is actually in a
  if i == 1
    inports(a)
  else
    unshifted = inports(nodes(a)[i-1])
    [Port(i, p.pin) for p in unshifted]
  end
end

function suboutports(a::CompositeArrow, i::ArrowId)
  #assert b is actually in a
  if i == 1
    outports(a)
  else
    unshifted = outports(nodes(a)[i-1])
    [Port(i, p.pin) for p in unshifted]
  end
end

"Is this arrow well formed? Are all its ports (and no others) connected?"
function iswellformed{I,O}(c::CompositeArrow{I,O})
  # Check no dangling ports
  # ports = Set([inports(c), outports(c)])
  ports = Set{Port}()
  push!(ports, sub)

  # check no double edges
  reversemap = Dict{Port,Port}()
  for (p1, p2) in edges(c)
    if haskey(reversemap, p2)
      error("port $p2 has more than once incoming edge")
    else
      reversemap[p2] = p1
    end
  end

  c
end

compose(a::PrimArrow, b::CompositeArrow) = compose(encapsulate(a), b)
compose(a::CompositeArrow, b::PrimArrow) = compose(a, encapsulate(b))
compose(a::PrimArrow, b::PrimArrow) = compose(encapsulate(a), encapsulate(b))

"""Takes two inputs side by side. The first one is modified using an arrow `a`,
  while the second is left unchanged."""
function first(a::Arrow{1,1})
  c = CompositeArrow{2, 1}()

  addnodes!(c, nodes(a))

  ## Add inner edges from a and b (where they exist)
  addedges!(c, inneredges(a))

  in_a = ingateports(a)
  @assert length(in_a) == 1

  out_a = outgateports(a)
  @assert length(out_a) == 1

  # Connet compposite input ot content input
  addedge!(c, Port(1, 1), in_a)

  # Connet compposite input ot content input
  addedge!(c, out_a, Port(1, 3))

  # Connect the pass-through edge
  addedge!(c, Port(1, 2), Port(2, 4))
  return c
end
