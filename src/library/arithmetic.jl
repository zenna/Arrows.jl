## Primitive Tensor Functions
## ==========================

begin
  """
  Real >> Real
  n >> n
  (xi for i = 1:n) >> (xi for i = 1:n)
  """
  local x = VarLenVarArray(:i, 1, :n, :x)
  local xnd = Arrows.ShapeArray(ConstantVar(Real), x)
  arith_type = Arrows.ExplicitArrowType{2,1}((xnd,xnd), (xnd,), SMTBase.ConstraintSet())
end

"Class of arrows for primitive unary arithmetic operations"
immutable ArithArrow <: PrimArrow{2, 1}
  typ::ArrowType
  name::Symbol
end

ArithArrow(s::Symbol) = ArithArrow(arith_type, s)
dimtyp(a::ArithArrow) = a.typ.dimtype
typ(a::ArithArrow) = a.typ
name(a::ArithArrow) = a.name

## Primitive Arithmetic Arrows
## ===========================

const addarr = ArithArrow(:+)
const minusarr = ArithArrow(:-)
const divsarr = ArithArrow(:/)
const mularr = ArithArrow(:*)
const powarr = ArithArrow(:^)
const logarr = ArithArrow(:log)

export addarr, minusarr, divsarr, mularr, powarr, logarr

## Unary Arithmetic operations
## ===========================
#
# "Unary arithmetic arrow - partially applied ArithArrow"
# immutable UnaryArithArrow{T} <: PrimArrow{1, 1}
#   name::Symbol
#   value::T
#   isnumfirst::Bool # is the number first, .e.g f(x) = (+)(3,x) => true
# end
#
# function dimtyp(x::UnaryArithArrow)
#   d = ndims(x.value)
#   c = Arrows.ConstantVar{Integer}(d)
#   Arrows.DimType{1,1}(tuple(c),tuple(c))
# end
#
# function typ(x::UnaryArithArrow)
#   sz = size(x.value)
#   shape = [Arrows.ConstantVar{Integer}(s) for s in sz]
#   shapevar = Arrows.FixedLenVarArray(tuple(shape...))
#   inp = Arrows.ShapeParams{Integer}(Arrows.PortName(:i), shapevar)
#   out = Arrows.ShapeParams{Integer}(Arrows.PortName(:o), shapevar)
#   Arrows.ArrowType{1,1}(dimtyp(x), tuple(inp), tuple(out))
# end
#
# name(x::UnaryArithArrow) = x.name
#
# "Partially evaluate. e.g. addarr(_, 10)"
# call(arr::ArithArrow, a::Type{_}, b::Type{_}) = arr
# call(arr::ArithArrow, a::Type{_}, b) = UnaryArithArrow(arr.name, b, false)
# call(arr::ArithArrow, a, b::Type{_}) = UnaryArithArrow(arr.name, a, true)
# call(arr::ArithArrow, a, b) = eval(arr.name)(a, b)
