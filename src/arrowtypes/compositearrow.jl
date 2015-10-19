
## Composite Arrows
## ================

# Edges should go from outports to inports.
# Edges with the boundary need special care, because an outport on the boundary is
# (or at least is connected to) an inport of the arrow from the outside world

"An arrow with `I` input ports and `O` output ports"
immutable CompositeArrow{I, O} <: Arrow{I,O}
  edges::Dict{OutPort, InPort}
  nodes::Vector{PrimArrow}
  CompositeArrow() = new{I,O}(Dict{Port, Port}(), Arrow[])
end

addnodes!{T<:Arrow}(c::CompositeArrow, nodes::Vector{T}) = push!(c.nodes, nodes...)
nodes(a::CompositeArrow) = a.nodes
nnodes(a::CompositeArrow) = length(nodes(a))

edges(a::CompositeArrow) = a.edges
addedges!(a::CompositeArrow, e::Dict{OutPort, InPort}) = merge!(a.edges, e)
addedge!(a::CompositeArrow, p1::Port, p2::Port) = a.edges[p1] = p2

# Printing
string{I,O}(x::CompositeArrow{I,O}) = "CompositeArrow{$I,$O} - $(nnodes(x)) subarrows"
print(io::IO, x::CompositeArrow) = print(io, string(x))
println(io::IO, x::CompositeArrow) = println(io, string(x))
show(io::IO, x::CompositeArrow) = print(io, string(x))
showcompact(io::IO, x::CompositeArrow) = print(io, string(x))

function inppintype(x::CompositeArrow, pinid::PinId)
  inport = edges(x)[OutPort(1,pinid)]
  # This means edge is passing all the way through to output and therefore
  # is Top (Any) type
  if isboundary(inport)
    CoolType(:Any)
  else
    inppintype(subarrow(x, inport.arrowid), inport.pinid)
  end
end

"All the inports contained by subarrows in `a`"
function subarrowinports(a::CompositeArrow)
  ports = InPort[]
  for i = 1:nnodes(a)
    push!(ports, subinports(a, i+1)...)
  end
  ports
end

"All the outports contained by subarrows in `a`"
function subarrowoutports(a::CompositeArrow)
  ports = OutPort[]
  for i = 1:nnodes(a)
    push!(ports, suboutports(a, i+1)...)
  end
  ports
end

outasinports{I,O}(a::CompositeArrow{I,O}) = [InPort(1, i) for i = 1:O]
inasoutports{I,O}(a::CompositeArrow{I,O}) = [OutPort(1, i) for i = 1:I]

"Get the inner (extends within arrow) outport with pinid `n` if it exists"
nthinneroutport{I,O}(::CompositeArrow{I,O}, n::PinId) =
  (@assert n <= I "fail: n($n) <= I($I)"; OutPort(1, n))

"Get the inner (extends within arrow) inport with pinid `n` if it exists"
nthinnerinport{I,O}(::CompositeArrow{I,O}, n::PinId) =
  (@assert n <= O "fail: n($n) <= O($O)"; InPort(1, n))

"All inports, both nested and boundary"
allinports(a::CompositeArrow) = vcat(outasinports(a), subarrowinports(a))::Vector{InPort}

"All outports, both nested and boundary"
alloutports(a::CompositeArrow) = vcat(inasoutports(a), subarrowoutports(a))::Vector{OutPort}

subarrow(a::CompositeArrow, arrowid::ArrowId) = a.nodes[arrowid-1]

function subinports(a::CompositeArrow, arrowid::ArrowId)
  @assert arrowid != 1
  arr = subarrow(a, arrowid)
  [InPort(arrowid, i) for i = 1:ninports(arr)]
end

function suboutports(a::CompositeArrow, arrowid::ArrowId)
  @assert arrowid != 1
  arr = subarrow(a, arrowid)
  [OutPort(arrowid, i) for i = 1:noutports(arr)]
end

"Is this arrow well formed? Are all its ports (and no others) connected?"
function iswellformed{I,O}(c::CompositeArrow{I,O})
  # println("Checking")
  inpset = Set{InPort}(allinports(c))
  outpset = Set{OutPort}(alloutports(c))

  # @show inpset
  # @show outpset
  # @show edges(c)

  for (outp, inp) in edges(c)
    if (outp in outpset) && (inp in inpset)
      # println("removing $outp")
      # println("removing $inp")
      delete!(outpset, outp)
      delete!(inpset, inp)
    else
      # error("arrow not well formed")
      println("not well formed $outp - $(outp in outpset) \n $inp - $(inp in inpset)")
      return false
    end
  end

  if isempty(inpset) && isempty(outpset)
    return true
  else
    println("some unconnected ports")
    return false
  end
end
