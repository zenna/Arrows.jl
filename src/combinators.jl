## Combinator Helpers
## ==================

"Union and wire"
function combine(a::Arrow, b::Arrow, inports::Vector{Port}, outports::Vector{Port}, inner_edges::Dict{Port, Port})
  c = CompositeArrow{length(inports), length(outports)}()
  c.edges = Dict()

  # Connect `inports` of new composite arrow to inports
  inp_edges = [Port(c, i, true) => inports[i] for i = 1:length(inports)]

  # Connect `outports` to outports of new composite arrow
  out_edges = [outports[i] => Port(c, i, false) for i = 1:length(outports)]

  # Add internal edges
  addedges!(c, merge(edges(a), edges(b), inp_edges, out_edges, inner_edges))
  return c
end

function compose(a::Arrow{1,1}, b::Arrow{1,1})
  # Find out which port connects to output of a (should be 1)
  in_a = flatinports(a)[1]
  out_a = flatoutports(a)[1]

  # Find out which port connects to inputs of b (should be 1)
  inp_b = flatinports(b)[1]
  out_b = flatoutports(b)[1]

  # Construct new arrow with inner edges of a and b but with
  c = CompositeArrow{1,1}()
  addedges!(c, inner_edges(a))
  addedges!(c, inner_edges(b))

  # Connect outpot of a to input of b
  addedges!(c, Dict(out_a => inp_b))

  # Connect first (only) inport to composite function to input of a
  link_parent_input!(c, 1, in_a)

  # Connect output of b to first (only) outport of composite function
  link_parent_output!(c, 1, out_a)
  c
end

## Primitive Combinators
## =====================
"Lifts a primitive function to an arrow"
lift{I,O}(a::PrimFunc{I,O}) = PrimArrow{I,O}(a.typ, a)

# ">>> Forward Arrow composition"
# function compose(a::Arrow{1,1}, b::Arrow{1,1})
#   i = inports(a)
#   o = outports(b)
#   combine(a, b, i, o, Dict(outports(a)[1] => inports(b)[1]))
# end

# "<<< Reverse Arrow composition"
# function revcompose(a::Arrow{1,1}, b::Arrow{1,1})
#   i = inports(a)
#   o = outports(b)
#   @assert length(i) == length(o)
#   combine(a, b, i, o, Dict(outports(a)[1] => inports(b)[1]))
# end

function first(a::Arrow{1,1})
  c = CompositeArrow{2, 1}()
  c.edges = edges(a)
  addedges!(c, Dict(Port(c, 1, true) => inports(a)[1]))
  addedges!(c, Dict(outports(a)[1] => Port(c, 1, false)))
  # Route second input diretly to second output (unmodified)
  addedges!(c, Dict(Port(c, 2, true) => Port(c, 2, false)))
  return c
end

function second(a::Arrow{1,1})
  c = CompositeArrow{2, 1}()
  c.edges = edges(a)
  addedges!(c, Dict(Port(c, 1, true) => inports(a)[1]))
  addedges!(c, Dict(outports(a)[1] => Port(c, 1, false)))
  # Route second input diretly to second output (unmodified)
  addedges!(c, Dict(Port(c, 2, true) => Port(c, 2, false)))
  return c
end

"(***)  :: y a c -> y b d -> y (a, b) (c, d) -- first and second combined"
function triplestar(a::Arrow{1,1}, b::Arrow{1,1})
  combine(a, b, vcat(inports(a), inports(b)), vcat(outports(a), outports(b)), Dict())
end

# "(&&&)  :: y a b -> y a c -> y a (b, c)      -- (***) on a duplicated value"
# function tripleand(a::Arrow{1,1}, b::Arrow{1,1})
#   ::Arrow{1,2}
# end
