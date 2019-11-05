module Sym

using Spec

using ..ArrowMod: Arrow, CompArrow, SubArrow, ArrowRef, AbstractPort, SubPort, Arrow, Port, PrimArrow
using ..Library
using ..Propagates

using DataStructures: DefaultDict

include("core.jl")
include("symprim.jl")
include("rewrite.jl")
include("convenience.jl")
include("scalar_solver.jl")
include("graph_solver.jl")

end