"""The Arrow Component Libary contains arrows, arrowsets, combinators for learning
  and inference problems"""
module Library

  using Arrows
  import Arrows: parameters, name, PrimArrow, ArrayType, ArrowType, typ

  include("library/arithmetic.jl")
  include("library/trigonometric.jl")
  include("library/array.jl")
  include("library/networks.jl")
  include("library/activations.jl")

  export simple_cnet
end
