"Interpret Arrow using Julia functions and conversion to Julia `Expr`s"
module JuliaTarget
using ..Arrows
importall ..Arrows
include("decode.jl")
end
