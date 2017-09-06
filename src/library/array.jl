"Gather"
struct GatherNdArrow <: PrimArrow end
name(::GatherNdArrow)::Symbol = :GatherNd
port_props(::GatherNdArrow) = bin_arith_port_props()
