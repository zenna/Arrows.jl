## Compilation and Execution of Arrows
## ===================================
import Base.Collections: PriorityQueue, dequeue!

"""Intermediate representation for function call
 (op1, op2, ..., opn) = f"""
immutable CallExpr
  f::Symbol
  inps::Vector{Symbol}
  ops::Vector{Symbol}
end

function convert(::Type{Expr}, x::CallExpr)
  Expr(:(=), Expr(:tuple, ops...), Expr(:call, ops...))
end

"""Compile to an imperative program so that it can be evaluated efficiently,
 and autodifferentiated."""
function compile(a::CompositeArrow)
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
  nodes = PriorityQueue(Arrow, Int)
  for a in arrows(a)
    nodes[a] = ninputs(a)
  end

  # TODO: remove input

  # For all the inputs to the Signal Update hose arrows
  funcapps = CallExpr[]
  while length(nodes) > 0
    @assert peek(a).second == 0 "No arrow without dependencies - Arrow incorrectly wired"
    arr = dequeue!(nodes)
    ip_symbs = [edgenames[port] for port in a.in_edges[arr]]
    op_symbs = Symbol[]
    for port in a.out_edges[arr]
      outsymb = gensym()
      edgenames[port] = outsymb
      push!(op_symbs, outsymb)

      # all nodes who recieve input from output of this node
      # nown have one less undefined dependency, so increase their priority
      priority = nodes[port[1]]
      nodes[port[1]] = priority - 1
    end

    push!(funcapps, CallExpr(name(arr), ip_symbs, op_symbs))
  end

  funcapps
end

"Apply an arrow to some input"
function call{T<:Real}(a::Arrow, v::Array{T})
  arr_expr = convert(Expr, a)
  eval(arr_expr)(v)
end
