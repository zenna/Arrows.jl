"Gather"
struct GatherNdArrow <: PrimArrow end
name(::GatherNdArrow)::Symbol = :GatherNd
props(::GatherNdArrow) = bin_arith_props()

"Reshape"
struct RehapeArrow <: PrimArrow end
name(::RehapeArrow)::Symbol = :reshape
props(::RehapeArrow) = bin_arith_props()

# struct GetIndexArrow <: PrimArrow end
# name(::GetIndexArrow)::Symbol = :getindex
# props(::GetIndexArrow) = bin_arith_props()
