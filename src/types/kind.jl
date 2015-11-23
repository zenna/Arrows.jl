
import SMTBase: VarArray
## Kind: types of type
## ===================
"All permissible types"
abstract Kind
printers(Kind)

## Array Type : Represent n-dimensional arrays
## ===========================================
"Represents a set of arrays through some parameterisation"
abstract ArrayType <: Kind

"Is an array type of a fixed number of dimensions"
isfixeddims(at::ArrayType) = isa(ndims(at), Integer)

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
#
# "Number of dimensions of the array this shape parameter represents"
# ndims(a::ShapeParams) = length(a.values)
# string(a::ShapeParams) = string("{", string(a.values),"}")

"Class of Arrays parameterised by values"
typealias ValueParams VarArray

abstract NonDetArray

"This is a nondeterminstic array"
immutable OkArray <: NonDetArray
  values::ParameterExpr{Array}
  elemtype::ElementParam
  dimtype::DimParam
  shapetype::ShapeParams
end

immutable ShapeArray <: NonDetArray
  elemtype::ElementParam
  shape::ShapeParams
end

ndims(s::ShapeArray) = length(s.shape)
shape(s::ShapeArray) = s.shape
eltype(s::ShapeArray) = s.elemtype

# Convenience
ShapeArray(s::Tuple) = ShapeArray(ConstantVar(Real), SMTBase.FixedLenVarArray(s))

"Nondeterminstic array specified by saying its equal to some array of variables"
immutable ValueArray <: NonDetArray
  value::VarArray
end

ValueArray(p::ParameterExpr) = ValueArray(SMTBase.Scalar(p))

# nubmer of dims is determined
ndims(v::ValueArray) = ndims(v.value)
eltype(v::ValueArray) = eltype(v.value)
shape(v::ValueArray) = shape(v.value)

# Printing
string(x::NonDetArray) = join([string(x.elemtype), string(x.dimtype), parens(string(x.shapetype))],"\n")
curly(x::AbstractString) = string("{",x,"}")
parens(x::AbstractString) = string("(",x,")")
square(x::AbstractString) = string("[",x,"]")

## Arrow Extentions
## ================
abstract ArrowType <: Kind

"Class of arrows parameterised by dimensionality of individual scalars"
immutable ExplicitArrowType{I, O} <: ArrowType
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

function go(x::ExplicitArrowType, f::Function; postprocess = identity)
  inps = [postprocess(string(f(ndarray))) for ndarray in x.inptypes]
  outs = [postprocess(string(f(ndarray))) for ndarray in x.outtypes]
  string(join(inps, ", "), " ⇝ ", join(outs, ", "))
end


function string(x::ExplicitArrowType)
  join([go(x, eltype), go(x, ndims), go(x, shape; postprocess = parens)], "\n")
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
  paramset = Set{Parameter{Integer}}()
  # FIXME: add constraints, d.constraints
  for dtype in vcat(d.inptypes..., d.outtypes...)
    @show dtype
    union!(paramset, parameters(dtype))
  end
  paramset
end
