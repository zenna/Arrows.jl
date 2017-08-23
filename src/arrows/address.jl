# """A reference to an Arrow
#
# In order to allow recursion and be space efficient, composite arrows can
# contain themselves or multiple copies of the same sub_arrow.
#
# However there are many cases where we need to talk about these different
# sub_arrows and hence we need a way to individually identify them.
#
# - Currently a port is identified by its arrow and an index
# - If we have two AddArrows in a composition there fist inports will be equal
# - But sometimes we need to address Ports individually
# - So we need some kind of addressing scheme that gives each port a unique address
# - Also gives each arrow a unique address
# - Has to account for the fact that we can have infinite recursion
#
# """
# # TODO: Should thsi subtype Arrow?

"A trace within an arrow uniquely defines a sub_arrow"
struct TraceArrowRef{I, O} <: ArrowRef{I, O}
  arr::CompArrow
  ids::Vector{Int}
end

function parent(trace::TraceArrowRef)
  @assert false
end

parent(portref::PortRef) = parent(portref.arrref)

function is_linked(portref1::PortRef, portref2::PortRef)
  same_parent = parent(portref1) == parent(portref2)
  # Find vertex corresponding to port_ref1 and port_reef 2 and see if they are
  # connected
end
