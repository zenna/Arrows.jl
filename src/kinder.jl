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
module Kinder
## Conventions
## ===========

# """
# In the defintiion:
# Anarrow :: a:{x_i for i = 1:n} >> b:[t, 2t] | 2t > 3 & t + 1 > 5
#
# There are severiable (x_i, n, t) variables.  These variables range over the
# integers.  They are used as parameters to define a set of arrays.
# They are not type variables because you could not replace them with a type.
#
# The variables a and b are argument variables.
# More precisely they are the names given to the space of functions defined by the
# parameterisations using the variables above.
#
# Or maybe they are just the names of the arguments, the concrete values which belong to that set
#
# Threre are no type variables perse.  We could have t hem, e.g
#
# Anarrow :: x >> b:[t, 2t]
# """


import Base: string
## Type expressions / variables
## ============================

"Gives names to things which can vary - parameters, argument names, type variables"
abstract Variable

"An expression for type variables which represent values of type `T`"
abstract ParameterExpr{T} <: Variable

"A parameter used within a parametric type, ranges over values of type `T`"
immutable Parameter{T} <: ParameterExpr{T}  # all type variables are integer based
  name::Symbol
end

string(x::Parameter) = string(x.name)

"An indexed type variable, used in VarLengthVar, e.g. `x_i` in [x_1 for i = 1:n]"
immutable IndexedParameter <: ParameterExpr{Int}
  name::Symbol
end

string(x::IndexedParameter) = string(x.name, "_i")

"A type variable after transformation, e.g. `2T`"
immutable CompositeParameter{T} <: ParameterExpr{T}
  expr::Expr
end

string(x::CompositeParameter) = string(x.expr)
convert(::Type{ParameterExpr}, x::Symbol) = Parameter(x)
convert(::Type{ParameterExpr}, x::Expr) = CompositeParameter(x)

## Type Arrays: arrays of type expressions
## =======================================

"""A fixed length vector of type expressions and constants"""
immutable FixedLenVarArray
  typs::Tuple{Vararg{ParameterExpr}}
end

string(x::FixedLenVarArray) = join(map(string, x.typs),", ")

"A vector of variable length of type expressions of `len`, e.g. s:[x_i for i = 1:n]"
immutable VarLenVarArray
  len::Parameter{Integer}
  expr::IndexedParameter
end

string(x::VarLenVarArray) = string("$(string(x.expr)) for i = 1:$(string(x.len))")

"""Datastructures for arrays of type expressions.
They are not not Kinds themselves; just a datastructure used by other Kinds"""
typealias VarArray Union{FixedLenVarArray, VarLenVarArray}
print(io::IO, a::VarArray) = print(io, string(a))
println(io::IO, a::VarArray) = println(io, string(a))
show(io::IO, a::VarArray) = print(io, a)

## Kinds
## =====

"All permissible types"
abstract Kind

# Kind printing
print(io::IO, x::Kind) = print(io, string(x))
println(io::IO, x::Kind) = println(io, string(x))
show(io::IO, x::Kind) = print(io, string(x))
showcompact(io::IO, x::Kind) = print(io, string(x))

## Array Type : Represent n-dimensional arrays
## ===========================================

"Class of types which represent arrays"
abstract ArrayType <: Kind

"""Class of arrays parameterised by their shape.
s:ShapedParameterisedArrayType{T} denotes `s` is an array which elements of type `T`
Elements in `s` correspond to the dimension sizes of s"""
immutable ShapeParams{T} <: ArrayType
  param::Parameter                  # e.g. s
  dimtypes::VarArray   # e.g. [1, 2t, p]
end

ndims(a::ShapeParams) = length(a.dimtypes)
ShapeParams(xs...) = ShapeParams(tuple(ParameterExpr[convert(ParameterExpr,x) for x in xs]...))
ShapeParams(x) = ArrayType((convert(ParameterExpr,x),))
string(a::ShapeParams) = string(string(a.param)":","{", string(a.dimtypes),"}")

## Int-Array : Represents n-dimensional array
## ==========================================

"""Class of Integer Arrays parameterised by values
s:IntegerArrayType denotes that `s` is an array of integers, elements in `s`
are values in the array"""
immutable ValueParams <: ArrayType
  param::Parameter
  values::VarArray
end

length(x::ValueParams) = length(values)
string(a::ValueParams) = string(string(a.param)":","[", string(a.values),"]")

## ArrowType : Represent types of arrow
## ====================================

"""Differentiable arrows take as input a collection of real valued arrays
 and output a collection of real valued a rray"""
immutable ArrowType{I, O} <: Kind
  inptypes::Tuple{Vararg{Kind}}
  outtypes::Tuple{Vararg{Kind}}
  constraints::Vector{ParameterExpr{Bool}}
  # function ArrowType(inptypes::Vector{ArrayType}, outtypes::Vector{ArrayType},
  #           constraints::Vector{ParameterExpr{Bool}})
  #   @assert length(inptypes) == I
  #   @assert length(outtypes) == O
  #   new{I,O}(inptypes, outtypes, constraints)
  # end
end

function string{I,O}(x::ArrowType{I,O})
  inpstring = string(join(map(string, x.inptypes), ", "))
  outstring = string(join(map(string, x.outtypes), ", "))
  constraints = string(join(map(string, x.constraints), " & "))
  "$inpstring >> $outstring | $constraints"
end

## Type Group
## ==========
#
# "A type group is a finite group of arrow types, it allows polymorphic functions"
# immutable ArrowTypeGroup
#   typs::Set{ArrowType}
# end

## TODO
# - provide means to construct type that:
# -- ensures same variable name isnt used for different things
# - parse type from string or using macro
# - give special notation for arrow type
# - clear up confusion between type variables and variabels
# - write convention


end
