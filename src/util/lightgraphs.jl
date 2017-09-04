# Light Graph Extensions

"""Partition the ports into weakly connected equivalence classes"""
function weakly_connected_component(edges::LG.DiGraph, i::Integer)::Vector{Int}
  cc = LG.weakly_connected_components(edges)
  filter(comp -> i ∈ comp, cc)[1]
end
