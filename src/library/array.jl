"Gather"
struct GatherNdArrow <: PrimArrow{2, 1} end
name(::GatherNdArrow)::Symbol = :GatherNd
port_props(::GatherNdArrow) = bin_arith_port_props()
