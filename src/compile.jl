## Compilation and Execution of Arrows
## ===================================

# Compilation turns an arrow into a series of function calls

typealias ArrowName Symbol
import Base.Collections: PriorityQueue, dequeue!, peek

"""Intermediate representation for function call
 (op1, op2, ..., opn) = f"""
immutable CallExpr
  name::Symbol
  inputsymbs::Vector{Symbol}
  outputsymbs::Vector{Symbol}
  outputtypes::Vector{ArrayType}
end

"""Represents an imperative function definition: a typed funtion declaration
  and a sqeuence of imperative calls (CallExprs).  Represents functions in form:
  function f(i0, i1)
    x2 = a(i0, i1)
    (x3,x4) = b(x2, x1)
    ...
    return o0, o1, ...
  end"""
immutable FuncDef
  name::Symbol                    # f
  inputsymbs::Vector{Symbol}      # i0, i1, ...
  inputtypes::Vector{ArrayType}

  outputsymbs::Vector{Symbol}     # o0, o1, ...
  outputtypes::Vector{ArrayType}

  calls::Vector{CallExpr}         # x2 = a(10, i1), ...
end

function convert(::Type{Expr}, x::CallExpr)
  Expr(:(=), Expr(:tuple, x.outputsymbs...), Expr(:call, x.f, x.inputsymbs...))
end

function convert(::Type{Expr}, f::FuncDef)
  header = Expr(:call, f.f, [:($x::Array{Float64}) for x in f.inputsymbs]...)
  ret = Expr(:return, Expr(:tuple, [x for x in f.outputsymbs]...))
  code = Expr(:block, [convert(Expr, fcall) for fcall in f.calls]..., ret)
  Expr(:function, header, code)
end

"Pops a subarray, adds names to its outputs and updates queue"
function handle_subarrow!(a::Arrow, edgenames::Dict{InPort, Symbol},
                          nodequeue::PriorityQueue,
                          outputsymbs::Vector{Symbol},
                          outputtypes::Vector{ArrayType})
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
  op_symbs = Symbol[]

  calloutputtypes = ArrayType[]

  # For each outport of arrow, generate a symbol name and mark as fulfilled
  for port in suboutports(a, arrowid)
    outsymb = genvar()
    ingateport = edges(a)[port]
    println("removing", ingateport)
    edgenames[ingateport] = outsymb
    push!(op_symbs, outsymb)

    t = outpintype(curr_arrow, port.pinid)
    push!(calloutputtypes, t)

    # all nodequeue who recieve input from output of this node
    # nown have one less undefined dependency, so increase their priority
    if ingateport.arrowid == 1
      @show noutports(a), ingateport.pinid
      outputsymbs[ingateport.pinid] = outsymb
      outputtypes[ingateport.pinid] = t
    else
      nodequeue[ingateport.arrowid] -=1
    end
  end
  CallExpr(name(nodes(a)[arrowid-1]), ip_symbs, op_symbs, calloutputtypes)
end

"Sets up priority queue to create sequence of function calls to emulate arrow"
function function_sequence{I,O}(
    na::NamedArrow{I,O}, to_visit::Set{NamedArrow}, seen_arrows::Set{ArrowName})

  a = na.arrow
  # We will give unique names to each edge, since an edge is uniquely defined by
  # an output port, we will use that to identify them
  edgenames = Dict{InPort, Symbol}()

  # Store each arrow associated with number of inputs (yet to be declared)
  nodequeue = PriorityQueue(ArrowId, Int)
  for i = 1:length(nodes(a))
    nodequeue[i+1] = ninports(nodes(a)[i]) # i+1 accounts for 1-as-self-port offset
  end

  inputsymbs = Symbol[]               # variable names for inputs to function
  inputtypes = ArrayType[]            # Types of input to function
  outputsymbs = Array(Symbol, O)      # variable names for outputs to function
  outputtypes = Array(ArrayType, O)   # Types of output to function

  # Gen input names and decrement count for all arrows connected to boundary edges
  for i = 1:I
    ingateport = edges(a)[OutPort(1, i)]  # which port connected to i-th na input
    newinpname = genvar()
    edgenames[ingateport] = newinpname      # gen name for this input

    push!(inputsymbs, newinpname)
    push!(inputtypes, inppintype(a, 1))

    if isboundary(ingateport)
      # if the input wires directly to the output then we'll say it has same name and type
      outputsymbs[ingateport.pinid] = newinpname
      outputtypes[ingateport.pinid] = inppintype(a, 1)
    else
      # otherwise it maps to a subarrow; decrement to account for having 'seen' this edge
      nodequeue[ingateport.arrowid] -= 1
    end
  end

  funcapps = CallExpr[]
  while length(nodequeue) > 0
    push!(funcapps, handle_subarrow!(a, edgenames, nodequeue, outputsymbs, outputtypes))
  end

  FuncDef(na.name, inputsymbs, inputtypes, outputsymbs, outputtypes, funcapps)
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
  funcdefs = FuncDef[]             # 1 funcdef per namedarray

  # While compiling a named arrow, may encounter other named arrows, add these to
  # list and keep compiling until none left
  while !isempty(to_visit)
    curr_na = pop!(to_visit)
    push!(seen_arrows, curr_na.name)
    funcdef = function_sequence(curr_na, to_visit, seen_arrows)
    push!(funcdefs, funcdef)
  end
  funcdefs
end

"Apply an arrow to some input"
function call{T<:Real}(a::Arrow, v::Array{T})
  arr_expr = convert(Expr, a)
  eval(arr_expr)(v)
end
