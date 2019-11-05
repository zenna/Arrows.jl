module Propagates

using Spec
using AutoHashEquals: @auto_hash_equals

using ..ArrowMod: CompArrow, SubArrow, ArrowRef, AbstractPort, SubPort, Arrow, Port, PrimArrow
using ..Trace: TraceValue, TraceSubArrow, TraceParent

export Size

export AbVals,
       IdAbVals,
       TraceAbVals,
       NmAbVals,
       SprtAbVals,
       PrtAbVals,
       XAbVals


include("core.jl")
include("meet.jl")        # Meeting (intersection) of domains
include("size.jl")        # Propagate size
include("singleton.jl")   # Propagate a singleton value
include("const.jl")       # Const type

end