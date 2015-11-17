"""The Arrow Component Libary contains arrows, arrowsets, combinators for learning
  and inference problems"""
module Library

  using Arrows
  import Arrows: parameters, name, PrimArrow, ArrayType, ArrowType, typ, dimtyp,
                 isfixeddims, DimType
  import Arrows: @shape, @arrtype, @intparams, @dimtype, @arrtype2
  import Arrows: _
  import Base: call

  import SMTBase: Variable, ParameterExpr, Parameter, ConstraintSet, ParameterSet,
                  ConstantVar, nonnegparam, IndexedParameter
                  
  include("library/arithmetic.jl")
  include("library/trigonometric.jl")
  include("library/array.jl")
  include("library/convolution.jl")
  # include("library/activations.jl")
  # include("library/networks.jl")

  export simple_cnet
end
