"""The Arrow Component Libary contains arrows, arrowsets, combinators for learning
  and inference problems"""
module Library

  using Arrows
  using SMTBase
  import Arrows: parameters, name, PrimArrow, ArrowType, typ, dimtyp,
                 ElementParam, DimParam, ShapeArray, ValueArray, ConstraintSet,
                 ExplicitArrowType
  import Arrows: @shape, @arrtype, @intparams, @dimtype, @arrtype2
  import Arrows: _
  import Base: call

  import SMTBase: Variable, ParameterExpr, Parameter, ConstraintSet, ParameterSet,
                  ConstantVar, nonnegparam, IndexedParameter

  import SMTBase: VarLenVarArray, FixedLenVarArray

  include("library/arithmetic.jl")
  include("library/convolution.jl")
  include("library/trigonometric.jl")
  include("library/distance.jl")
  # include("library/array.jl")
  # include("library/activations.jl")
  # include("library/networks.jl")

  # Data Types
  include("library/stack.jl")

  export simple_cnet
end
