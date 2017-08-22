"""A reference to an Arrow

In order to allow recursion and be space efficient, composite arrows can
contain themselves or multiple copies of the same sub_arrow.

However there are many cases where we need to talk about these different
sub_arrows and hence we need a way to individually identify them.

- Currently a port is identified by its arrow and an index
- If we have two AddArrows in a composition there fist inports will be equal
- But sometimes we need to address Ports individually
- So we need some kind of addressing scheme that gives each port a unique address
- Also gives each arrow a unique address
- Has to account for the fact that we can have infinite recursion

"""
abstract type ArrowRef end
# TODO: Should thsi subtype Arrow?

"`id`th sub_arrow in (some kind of) ordering of sub_arrows of `arr`"
struct SubArrowRef <: ArrowRef
  arr::CompArrow
  id::Int
end

"A trace within an arrow uniquely defines a sub_arrow"
struct TraceArrowRef <: ArrowRef
  arr::CompArrow
  ids::Vector{Int}
end

"Unique reference to a port"
struct PortRef
  arrref::ArrowRef
  id::Int
end
