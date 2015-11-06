## Kind: types of type
## ===================
"All permissible types"
abstract Kind
printers(Kind)

## Array Type : Represent n-dimensional arrays
## ===========================================
"Class of types which represent arrays"
abstract ArrayType <: Kind

"Scalar represents a scalar value, e.g. an integer, or a real"
immutable Scalar{T} <: Kind
  val::ParameterExpr{T}
end

ndims(s::Scalar) = 0
string(s::Scalar) = string(s.val)

"Is an array type of a fixed number of dimensions"
isfixeddims(at::ArrayType) = isa(ndims(at), Integer)

"""Class of arrays parameterised by their shape.
s:ShapedParameterisedArrayType{T} denotes `s` is an array which elements of type `T`
Elements in `s` correspond to the dimension sizes of s"""
immutable ShapeParams{T} <: ArrayType
  portname::PortName                  # e.g. s
  dimtypes::VarArray             # e.g. [1, 2t, p]
end

"Number of dimensions of the array this shape parameter represents"
ndims(a::ShapeParams) = length(a.dimtypes)
string(a::ShapeParams) = string(string(a.portname)":","{", string(a.dimtypes),"}")

## Int-Array : Represents n-dimensional array
## ==========================================
"""Class of Integer Arrays parameterised by values
s:IntegerArrayType denotes that `s` is an array of integers, elements in `s`
are values in the array"""
immutable ValueParams <: ArrayType
  portname::PortName
  values::VarArray
end

"Number of dimensions of the integer array this ValueParams represents"
ndims(a::ValueParams) = ndims(a.values)
length(a::ValueParams) = length(a.values)
string(a::ValueParams) = string(string(a.portname)":","[", string(a.values),"]")

## Dimension Type
## ==============
immutable DimType{I, O} <: Kind
  inptypes::Tuple{Vararg{ParameterExpr{Integer}}}
  outtypes::Tuple{Vararg{ParameterExpr{Integer}}}
  # constraints::ConstraintSet #FIXME: Enable
end

string(d::DimType) = string(join([string(t) for t in d.inptypes], ", "), " >> ",
                            join([string(t) for t in d.outtypes]))


"Return a new dimension type with variables substituted"
function substitute{I, O}(d::DimType{I, O}, varmap::VarMap)
  newinptypes = map(t->substite(t,varmap), d.inptypes)
  newouttypes = map(t->substite(t,varmap), d.outtypes)
  # FIXME: add constraints
  DimType{I, O}(newinptypes, newouttypes)
end

"Set of unique dimensionality parameters"
function parameters(d::DimType)
  paramset = Set{Parameter{Integer}}()
  # FIXME: add constraints, d.constraints
  for dtype in vcat(d.inptypes..., d.outtypes...)
    @show dtype
    union!(paramset, parameters(dtype))
  end
  paramset
end

## ArrowType : Represent types of arrow
## ====================================
"""an arrow type represents the type at the input and type of output
These types could be array types, or other arrows types."""
immutable ArrowType{I, O} <: Kind
  dimtype::DimType{I,O}
  inptypes::Tuple{Vararg{Kind}}
  outtypes::Tuple{Vararg{Kind}}
  constraints::ConstraintSet

  "Construct DimTypes from Arrowtypes if not given"
  function ArrowType(
      dimtype::DimType{I,O},
      inptypes::Tuple{Vararg{Kind}},
      outtypes::Tuple{Vararg{Kind}},
      constraints::ConstraintSet)
    @assert length(inptypes) == I
    @assert length(outtypes) == O
    new{I,O}(dimtype, inptypes, outtypes, constraints)
  end
  function ArrowType(
    dimtype::DimType{I,O},
    inptypes::Tuple{Vararg{Kind}},
    outtypes::Tuple{Vararg{Kind}})
    new{I, O}(dimtype, inptypes, outtypes, ConstraintSet())
  end
end

function string{I,O}(x::ArrowType{I,O})
  inpstring = string(join(map(string, x.inptypes), ", "))
  outstring = string(join(map(string, x.outtypes), ", "))
  constraints = string(join(map(string, x.constraints), " & "))
  dimtype = string(x.dimtype)
  shapetype = "$inpstring >> $outstring $(!(isempty(constraints)) ? constraints : " ")"
  "$dimtype \n $shapetype"
end
