
## Kind: types of type
## ===================
"All permissible types"
abstract Kind
printers(Kind)

## Array Type : Represent n-dimensional arrays
## ===========================================
"""Class of arrays parameterised by dimensionality.
A parameter that represents the dimensionality of an array"""
typealias ElementParam ParameterExpr{DataType} #FIXME, get a better type than datatype

"""Class of arrays parameterised by dimensionality.
A parameter that represents the dimensionality of an array"""
typealias DimParam ParameterExpr{Integer}

"""Class of arrays parameterised by their shape.
s:ShapedParameterisedArrayType denotes `s` is an array which elements of type `T`
Elements in `s` correspond to the dimension sizes of s"""
typealias ShapeParams VarArray                  # e.g. [1, 2t, p]

"Class of Arrays parameterised by values"
typealias ValueParams VarArray

## Non Determinstic Arrays
## =======================
"A nondeterministic array represents a set of arrays."
abstract NonDetArray

"A non deterministic parameterised by a finite or variable set of shape parameters"
immutable ShapeArray <: NonDetArray
  elemtype::ElementParam
  shape::ShapeParams
end

# Convenience
ShapeArray(s::Tuple) = ShapeArray(ConstantVar(Real), SMTBase.FixedLenVarArray(s))
ndims(s::ShapeArray) = length(s.shape)
shape(s::ShapeArray) = s.shape
eltype(s::ShapeArray) = s.elemtype

function reifydim(x::ShapeArray)
  @assert !isfixeddims(x.shape)
  error("unimplemetned")
end
## Value Array
## ===========
"Nondeterminstic array specified as equal to some array of variables (and/or constants)"
immutable ValueArray <: NonDetArray
  value::VarArray
end

ValueArray(p::ParameterExpr) = ValueArray(SMTBase.Scalar(p))
ndims(v::ValueArray) = ndims(v.value)
eltype(v::ValueArray) = eltype(v.value)
shape(v::ValueArray) = shape(v.value)

function reify(x::ShapeArray, varmap)
  n = ndims(x)
end

## Arrow Extentions
## ================
abstract ArrowType{I, O} <: Kind

"Class of arrows parameterised by dimensionality of individual scalars"
immutable ExplicitArrowType{I, O} <: ArrowType{I, O}
  inptypes::Tuple{Vararg{NonDetArray}}
  outtypes::Tuple{Vararg{NonDetArray}}
  constraints::ConstraintSet
  function ExplicitArrowType(
      inptypes::Tuple{Vararg{NonDetArray}},
      outtypes::Tuple{Vararg{NonDetArray}},
      constraints::ConstraintSet)
    @assert length(inptypes) == I && length(outtypes) == O
    new{I,O}(inptypes, outtypes, constraints)
  end
end

addconstraints{I, O}(x::ExplicitArrowType{I, O}, cs::ConstraintSet) =
  ExplicitArrowType{I, O}(x.inptypes, x.outtypes, union(x.constraints, cs))
addconstraint(x::ExplicitArrowType, c::ParameterExpr{Bool}) =
  addconstraints(x, ConstraintSet([c]))

"Generates the a string for a particular feature `f` (e.g. ndims) of an arrow type"
function arrtypf(x::ExplicitArrowType, f::Function; postprocess = identity)
  inps = [postprocess(string(f(ndarray))) for ndarray in x.inptypes]
  outs = [postprocess(string(f(ndarray))) for ndarray in x.outtypes]
  string(join(inps, ", "), " ⇝ ", join(outs, ", "))
end

finptypes(x::ExplicitArrowType, f::Function) = [f(ndarray) for ndarray in x.inptypes]
fouttypes(x::ExplicitArrowType, f::Function) = [f(ndarray) for ndarray in x.outtypes]
ftypes(x::ExplicitArrowType, f::Function) = vcat(finptypes(x, f), fouttypes(x, f))

function string(x::ExplicitArrowType)
  join([arrtypf(x, eltype), arrtypf(x, ndims), arrtypf(x, shape; postprocess = parens)], "\n")
end

"Return a new dimension type with variables substituted,"
function substitute{I, O}(d::ExplicitArrowType{I, O}, varmap::Dict) #FIXME, make types tighter
  newinptypes = [substitute(t, varmap) for t in d.inptypes]
  newouttypes = [substitute(t, varmap) for t in d.outtypes]
  # FIXME: add constraints
  ExplicitArrowType{I, O}(tuple(newinptypes...), tuple(newouttypes...))
end

"Set of unique dimensionality parameters"
function parameters(d::ExplicitArrowType)
  paramset = Set{Parameter}()
  # FIXME: add constraints, d.constraints
  for dtype in vcat(d.inptypes..., d.outtypes...)
    @show dtype
    union!(paramset, parameters(dtype))
  end
  paramset
end
