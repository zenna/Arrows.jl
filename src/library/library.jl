"""The Arrow Library contains arrows and combinators for inference problems"""
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

  include("arithmetic.jl")
  include("convolution.jl")
  include("trigonometric.jl")
  include("distance.jl")
  # include("array.jl")
  # include("activations.jl")
  # include("networks.jl")

  # Data Types
  include("stack.jl")

  export simple_cnet
end
