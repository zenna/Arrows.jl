## Compilation and Execution of Arrows
## ===================================
import Base.Collections: PriorityQueue, dequeue!, peek

immutable FuncDef
  f::Symbol
  inps::Vector{Symbol}
  outs::Vector{Symbol}
  calls::Vector{CallExpr}
end

"""Intermediate representation for function call
 (op1, op2, ..., opn) = f"""
immutable CallExpr
  f::Symbol
  inps::Vector{Symbol}
  outs::Vector{Symbol}
end

function convert(::Type{Expr}, x::CallExpr)
  Expr(:(=), Expr(:tuple, ops...), Expr(:call, ops...))
end

"""Compile to an imperative program so that it can be evaluated efficiently,
 and autodifferentiated."""
function compile{I,O}(a::CompositeArrow{I,O})
  @show edges(a)
  # This algorithm works only for 'causal' arrows with no loops
  # The idea is to build an imperative program of the form
  # (a,b) = f(ip1,ip2); (c,) = g(a); d = h(b,c); ...
  # In order to make sure every variable is defined before it is used, we will
  # Associate each subarrow with the number of dependencies it has which have
  # been defined.  The only subarrows without any dependencies are those connected
  # to the input.  Pull any subarrow with no dependencies, construct

  edgenames = Dict{Port, Symbol}()
  # We will give unique names to each edge, since an edge is uniquely defined by
  # an output port, we will use that to identify them

  # Store each arrow associated with number of inputs (yet to be declared)
  nodequeue = PriorityQueue(ArrowId, Int)
  for i = 1:length(nodes(a))
    nodequeue[i+1] = ninports(nodes(a)[i])
  end
  @show nodequeue

  inputsymbs = Symbol[]
  # Remove input
  for i = 1:I
    @show edges(a)
    ingateport = edges(a)[Port(1, i)]
    edgenames[ingateport] = gensym()
    push!(inputsymbs, edgenames[ingateport])
    if !isboundary(ingateport)
      nodequeue[ingateport.arrow] -= 1
    end
  end

  # For all the inputs to the Signal Update hose arrows
  funcapps = CallExpr[]
  while length(nodequeue) > 0
    @assert peek(nodequeue).second == 0 "No arrow without dependencies - Arrow incorrectly wired $nodequeue"
    arrid = dequeue!(nodequeue)
    ip_symbs = [edgenames[port] for port in subinports(a, arrid)]
    op_symbs = Symbol[]
    println("arrow: $arrid")
    println(suboutports(a, arrid))
    println("")
    for port in suboutports(a, arrid)
      outsymb = gensym()
      ingateport = edges(a)[port]
      println("removing", ingateport)
      edgenames[ingateport] = outsymb
      push!(op_symbs, outsymb)

      # all nodequeue who recieve input from output of this node
      # nown have one less undefined dependency, so increase their priority
      if ingateport.arrow != 1
        nodequeue[ingateport.arrow] -=1
      end
    end
    push!(funcapps, CallExpr(name(nodes(a)[arrid-1]), ip_symbs, op_symbs))
  end

  FuncDef(name(a), funcapps)
end

"Apply an arrow to some input"
function call{T<:Real}(a::Arrow, v::Array{T})
  arr_expr = convert(Expr, a)
  eval(arr_expr)(v)
end
