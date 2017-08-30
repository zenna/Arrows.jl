"Interpret Arrow using Julia functions and conversion to Julia `Expr`s"
module JuliaTarget
using ..Arrows
importall ..Arrows

import Arrows: interpret
export interpret

include("decode.jl")
end
