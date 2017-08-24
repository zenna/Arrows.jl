"A trace within an arrow uniquely defines a sub_arrow"
struct TraceArrowRef{I, O} <: ArrowRef{I, O}
  arr::CompArrow
  ids::Vector{Int}
end

function parent(trace::TraceArrowRef)
  @assert false
end
