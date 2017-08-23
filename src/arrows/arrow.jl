"A relation is a kind of undirected computational model over `N` variables"
abstract type Relation{N} end

"An Arrow of `I` inputs and `O` outputs"
abstract type Arrow{I, O} <: Relation{IO} end

abstract type ArrowRef{I, O} <: Arrow{I, O} end

"Is `arr` a reference?"
is_ref(arr::Arrow) = isa(arr, ArrowRef)
