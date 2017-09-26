"Gather"
struct GatherNdArrow <: PrimArrow end
name(::GatherNdArrow)::Symbol = :GatherNd
props(::GatherNdArrow) = bin_arith_props()
