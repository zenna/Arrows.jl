## Compilation and Execution of Arrows
## ===================================

# The goal of compilation is to order a composite arrow into a sequence of
# of calls to its arrows
typealias ArrowName Symbol

"An arrow with pins labelled with names"
immutable LabelledArrow{I, O} <: Arrow{I, O}
  arr::Arrow{I, O}
  inpsymbs::Vector{Symbol}
  outsymbs::Vector{Symbol}
  function LabelledArrow(arr::Arrow{I, O}, inpsymbs::Vector{Symbol}, outsymbs::Vector{Symbol})
    @assert length(inpsymbs) == I
    @assert length(outsymbs) == O
    new(arr, inpsymbs, outsymbs)
  end
end

immutable DecomposedArrow
  name::ArrowName
  inputsymbs::Vector{Symbol}
  outputsymbs::Vector{Symbol}
  arrowsequence::Vector{LabelledArrow}
end

"Pops a subarray, adds names to its outputs and updates queue"
function handle_subarrow!(a::Arrow,
                          edgenames::Dict{InPort, Symbol},
                          nodequeue::PriorityQueue,
                          parent::Arrow,
                          outputsymbs::Vector{Symbol})
  # For all the inputs to the Signal Update hose arrows
  @assert peek(nodequeue).second == 0 "Arrow incorrectly wired.\n $nodequeue"

  # Pop arrow that has all dependencies fulfilled
  arrowid = dequeue!(nodequeue)
  curr_arrow = subarrow(a, arrowid)

  # Add this current arrow to tovisit list if we haven't seen it before
  if isa(curr_arrow, NamedArrow) && curr_arrow.name ∉ seen_arrows
    push!(to_visit, curr_arrow)
  end

  ip_symbs = [edgenames[port] for port in subinports(a, arrowid)]
  op_symbs = Symbol[]     # names for outputs from this arrow

  # For each outport of arrow, generate a symbol name and mark as fulfilled
  for port in suboutports(a, arrowid)
    outsymb = genvar()
    ingateport = edges(a)[port]
    edgenames[ingateport] = outsymb
    push!(op_symbs, outsymb)

    # all nodequeue who recieve input from output of this node
    # nown have one less undefined dependency, so increase their priority
    if ingateport.arrowid == 1
      @show noutports(a), ingateport.pinid
      outputsymbs[ingateport.pinid] = outsymb
    else
      nodequeue[ingateport.arrowid] -=1
    end
  end

  LabelledArrow{ninports(curr_arrow), noutports(curr_arrow)}(curr_arrow, ip_symbs, op_symbs)
end

"Sets up priority queue to create sequence of function calls to emulate arrow"
function function_sequence{I,O}(
    na::NamedArrow{I,O}, to_visit::Set{NamedArrow}, seen_arrows::Set{ArrowName})

  a = na.arrow
  # We will give unique names to each edge, since an edge is uniquely defined by
  # an inport, we will use that to identify them
  edgenames = Dict{InPort, Symbol}()

  # Store each arrow associated with number of inputs (yet to be declared)
  nodequeue = PriorityQueue(ArrowId, Int)
  for i = 1:length(nodes(a))
    nodequeue[i+1] = ninports(nodes(a)[i]) # i+1 accounts for 1-as-self-port offset
  end

  inputsymbs = Symbol[]               # variable names for inputs to function
  outputsymbs = Array(Symbol, O)      # variable names for outputs to function

  # Gen input names and decrement count for all arrows connected to boundary edges
  for i = 1:I
    ingateport = edges(a)[OutPort(1, i)]    # which port connected to i-th na input
    newinpname = genvar()
    edgenames[ingateport] = newinpname      # gen name for this input

    push!(inputsymbs, newinpname)

    if isboundary(ingateport)
      # if the input wires directly to the output then we'll say it has same name
      outputsymbs[ingateport.pinid] = newinpname
    else
      # otherwise it maps to a subarrow; decrement to account for having 'seen' this edge
      nodequeue[ingateport.arrowid] -= 1
    end
  end

  labelledarrs = LabelledArrow[]
  while length(nodequeue) > 0
    push!(labelledarrs, handle_subarrow!(a, edgenames, nodequeue, a, outputsymbs))
  end

  DecomposedArrow(na.name, inputsymbs, outputsymbs, labelledarrs)
end

# This algorithm works only for 'causal' arrows with no loops
# The idea is to build an imperative program of the form
# (a,b) = f(ip1,ip2); (c,) = g(a); d = h(b,c); ...
# In order to make sure every variable is defined before it is used, we will
# Associate each subarrow with the number of dependencies it has which have
# been defined.  The only subarrows without any dependencies are those connected
# to the input.  Pull any subarrow with no dependencies, construct
"""Compile to an imperative program so that it can be evaluated efficiently,
 and autodifferentiated.

 Returns Vector{FuncDef} where the name of arrow `na` will be name of one of
 returned `funcdefs and all other funcdefs correspond to subarrows of `na`."""
function compile{I,O}(na::NamedArrow{I,O})

  to_visit = Set{NamedArrow}([na]) # will add named arrows seen within `na` (recursively)
  seen_arrows = Set{ArrowName}()   # don't revisit compiled named arrow
  decomarrs = DecomposedArrow[]             # 1 funcdef per namedarray

  # While compiling a named arrow, may encounter other named arrows, add these to
  # list and keep compiling until none left
  while !isempty(to_visit)
    curr_na = pop!(to_visit)
    push!(seen_arrows, curr_na.name)
    decomarr = function_sequence(curr_na, to_visit, seen_arrows)
    push!(decomarrs, decomarr)
  end
  decomarrs
end
