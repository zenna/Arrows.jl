"Interpret Arrow using Julia functions and conversion to Julia `Expr`s"
module JuliaTarget
using ..Arrows
importall ..Arrows

import ..Arrows: interpret, expr
import Arrows: interpret, Target
export interpret,
       expr

"Used to dispatch on"
struct JLTarget <: Target end

include("interpret.jl")
include("expr.jl")

end
