module Transform
import LightGraphs; const LG = LightGraphs

using Spec

using ..ArrowMod: Arrow, PortIdMap, SubArrow, SubPortMap, CompArrow, SubArrow, ArrowRef, AbstractPort, SubPort, Arrow, Port, PrimArrow, PortMap, ArrowName, Link
using ..Trace: TraceParent
using ..Propagates: AbVals, IdAbVals, TraceAbVals, NmAbVals, SprtAbVals, PrtAbVals, XAbVals
using ..Library

export rm_partially_loose_sub_arrows!

export invert,
       pgf,
       aprx_invert,
       aprx_totalize!,
       domain_error,
       domain_error!,
       duplify!

include("walk.jl")
include("tracewalk.jl")
include("duplify.jl")
include("remove.jl")
include("invert.jl")
include("pgf.jl")
include("invprim.jl")
include("compcall.jl")
include("totalize.jl")
include("totalizeprim.jl")
include("domainerror.jl")
include("domainerrorprim.jl")

end