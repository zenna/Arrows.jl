module Compile
import LightGraphs; const LG = LightGraphs

using Spec

using DataStructures: PriorityQueue, peek, dequeue!
import Base: Iterators

using ..Values
using ..Library
using ..ArrowMod
export interpret

include("policy.jl")
include("depend.jl")
include("detpolicy.jl")
include("imperative.jl")
include("interpret.jl")
include("call.jl")
include("ordering.jl")

end