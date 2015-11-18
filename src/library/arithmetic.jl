## Primitive Tensor Functions
## ==========================

begin
  local etype = ElementParam(ConstantVar(Real))
  local n = nonnegparam(Integer, :n)
  local nd = DimParam(n)
  local x_i = SMTBase.IndexedParameter(SMTBase.Parameter{Integer}(:x), :i)
  local shp = Arrows.ShapeParams(Arrows.VarLenVarArray(1, n, x_i))


  local i1_i = SMTBase.IndexedParameter(SMTBase.Parameter{Integer}(:i1), :i)
  local valsi1 = Arrows.ValueParams(Arrows.VarLenVarArray(1, n, i1_i))
  local i2_i = SMTBase.IndexedParameter(SMTBase.Parameter{Integer}(:i2), :i)
  local valsi2 = Arrows.ValueParams(Arrows.VarLenVarArray(1, n, i2_i))

  local o1_i = SMTBase.IndexedParameter(SMTBase.Parameter{Integer}(:o1), :i)
  local valso1 = Arrows.ValueParams(Arrows.VarLenVarArray(1, n, o1_i))

  ##
  local darrow = ArrowParam{2, 1, DimParam}((nd,nd),(nd,), ConstraintSet())
  local etypearrow = ArrowParam{2, 1, ElementParam}((etype,etype),(etype,), ConstraintSet())
  local shparrow  = ArrowParam{2, 1, Arrows.ShapeParams}((shp,shp),(shp,), ConstraintSet())
  local valarrow  = ArrowParam{2, 1, Arrows.ValueParams}((valsi1,valsi2),(valso1,), ConstraintSet())

  arith_typ = ExplicitArrowType(etypearrow, darrow, shparrow, valarrow, ConstraintSet())

end

# const arith_dimtype = @dimtype [n, n] [n]
# const a = @shape a [x_i for i = 1:n]
# "a:{x_i for i = 1:n}, a:{x_i for i = 1:n} >> a:{x_i for i = 1:n}"
# const arith_typ = @arrtype2 arith_dimtype [a, a] [a]

"Class of arrows for primitive unary arithmetic operations"
immutable ArithArrow <: PrimArrow{2, 1}
  typ::ArrowType
  name::Symbol
end

ArithArrow(s::Symbol) = ArithArrow(arith_typ, s)

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
