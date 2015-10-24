## Kinds, types of types
## =====================

## Syntax (TODO)
# Scalar
# Tensor
# ValueType - Int8, Int16, Int32,
# Float16
#
# ## Array Types
# Int
# Real
# []                  # Real[]
# Float64{1,3,T}      # 3D - array of size 1 x 3 x T
# Real{1,3,T}         #
# {1,3,T}             # Equivalent to above
# Int64{1,2T,T}  | T > 0
# [1, 2, T]             # A fixed size vector of length of a particular type, with values for the
# [A 2  | A + B == 5  # Fixed size matrix of size 2*2
#  3 B]

"An expression for type variables"
abstract TypeExpr{T}

"A type variable, e.g. `T`"
immutable TypeVariable <: TypeExpr{Int}  # Size of array dimension represents a integer
  expr::Symbol
end

"A type after transformation, e.g. `2T`"
immutable TypeExprComposite <: TypeExpr{Int}
  expr::Expr
end

convert(::Type{TypeExpr}, x::Symbol) = TypeVariable(x)
convert(::Type{TypeExpr}, x::Expr) = TypeExprComposite(x)

## Array Type : Represent n-dimensional arrays
## ===========================================

"Type of an nd-array, each element of `s` corresponds to a dimension of the array"
immutable ArrayType
  @compat dimtypes::Tuple{Vararg{TypeExpr}}
end

ndims(a::ArrayType) = length(a.dimtypes)
ArrayType(xs...) = ArrayType(tuple(TypeExpr[convert(TypeExpr,x) for x in xs]...))
ArrayType(x) = ArrayType((convert(TypeExpr,x),))

string(x::TypeExpr) = string(x.expr)
string(a::ArrayType) = string("{", join(map(string, a.dimtypes),", "), "}")
print(io::IO, a::ArrayType) = print(io, string(a))
println(io::IO, a::ArrayType) = println(io, string(a))
show(io::IO, a::ArrayType) = print(io, a)

## ArrowType : Represent types of arrow
## ====================================

"""Differentiable arrows take as input a collection of real valued arrays
 and output a collection of real valued a rray"""
immutable ArrowType{I, O}
  inptypes::Vector{ArrayType}
  outtypes::Vector{ArrayType}
  constraints::Vector{TypeExpr{Bool}}
  # function ArrowType(inptypes::Vector{ArrayType}, outtypes::Vector{ArrayType},
  #           constraints::Vector{TypeExpr{Bool}})
  #   @assert length(inptypes) == I
  #   @assert length(outtypes) == O
  #   new{I,O}(inptypes, outtypes, constraints)
  # end
end

function string{I,O}(x::ArrowType{I,O})
  inpstring = string(join(map(string, x.inptypes), ", "))
  outstring = string(join(map(string, x.outtypes), ", "))
  constraints = "C (TODO)"
  "$inpstring >> $outstring | $constraints"
end

print(io::IO, x::ArrowType) = print(io, string(x))
println(io::IO, x::ArrowType) = println(io, string(x))
show(io::IO, x::ArrowType) = print(io, string(x))
showcompact(io::IO, x::ArrowType) = print(io, string(x))

## Type Group
## ==========

"A type group is a finite group of arrow types, it allows polymorphic functions"
immutable ArrowTypeGroup
  typs::Set{ArrowType}
end
