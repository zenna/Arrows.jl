"Interpret Arrow using Julia functions and conversion to Julia `Expr`s"
module JuliaTarget
using Spec

using ..Arrows
import ..Arrows: interpret
import Arrows: interpret, Target
export expr

"Julia target fordispatch"
struct JLTarget <: Target end

include("interpret.jl")
include("expr.jl")

"Compile `arr` into Julia program"
Arrows.Compile.compile(arr::Arrow, target::Type{JLTarget}) = JuliaTarget.exprs(arr)

end
