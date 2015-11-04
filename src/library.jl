"""The Arrow Component Libary contains arrows, arrowsets, combinators for learning
  and inference problems"""
module Library

  using Arrows
  import Arrows: parameters, name, PrimArrow, ArrayType, ArrowType, typ, dimtyp,
                 isfixeddims
  import Arrows: @shape, @arrtype, @intparams, @dimtype, @arrtype2
  import Arrows: _
  import Base: call

  include("library/arithmetic.jl")
  include("library/trigonometric.jl")
  include("library/array.jl")
  # include("library/convolution.jl")
  # include("library/activations.jl")
  # include("library/networks.jl")

  export simple_cnet
end