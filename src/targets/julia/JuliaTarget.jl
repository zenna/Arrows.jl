"Interpret Arrow using Julia functions and conversion to Julia `Expr`s"
module JuliaTarget
using ..Arrows
importall ..Arrows
using Spec

import ..Arrows: interpret, expr
import Arrows: interpret, Target, compile
export interpret,
       expr

"Julia target fordispatch"
struct JLTarget <: Target end

include("interpret.jl")
include("expr.jl")

"Compile `arr` into Julia program"
compile(arr::Arrow, target::Type{JLTarget}) = JuliaTarget.exprs(arr)

export compile
end
