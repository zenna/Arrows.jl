"Gather"
struct GatherNdArrow <: PrimArrow{2, 1} end
name(::GatherNdArrow)::Symbol = :GatherNd
port_attrs(::GatherNdArrow) = bin_arith_port_attrs()
