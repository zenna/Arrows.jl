## Kinds: types of types
## =====================

## Type expressions / variables
## ============================
"Gives names to things which can vary - parameters, port names, type variables"
abstract Variable
printers(Variable)

"An expression for parameters which represent values of type `T`"
abstract ParameterExpr{T} <: Variable

"A parameter used within a parametric type, ranges over values of type `T`"
immutable Parameter{T <: Number} <: ParameterExpr{T}  # all type variables are integer based
  name::Symbol                              # e.g. x
end

string(x::Parameter) = string(x.name)

"A set of constraints"
# typealias ConstraintSet Tuple{Vararg{ParameterExpr{Bool}}}
typealias ConstraintSet Set{ParameterExpr{Bool}}
string(constraints::ConstraintSet) = join(map(string, constraints), " & ")

"A constrained parameter used within a parametric type, ranges over values of type `T`"
immutable ConstrainedParameter{T} <: ParameterExpr{T}
  param::Parameter{T}                       # e.g. x
  constraints::ConstraintSet                # e.g. x | x > 10
  ConstrainedParameter(p::Parameter{T}) = new{T}(p, ConstraintSet())
  ConstrainedParameter(p::Parameter, constraints) =
    new{T}(p, constraints)
end

"Non negative parameter of numeric type `T`, e.g. for dimension sizes."
function nonnegparam{T<:Number}(::Type{T}, name::Symbol)
  p = Parameter{T}(name)
  constraint = TransformedParameter{Bool}(:($p>=0))
  ConstrainedParameter{T}(p, ConstraintSet([constraint]))
end

string(c::ConstrainedParameter; withconstraints::Bool = false) =
  string(c.param, !(isempty(c.constraints)) ? string(" | ", string(c.constraints)) : " ")

"An indexed type variable, used in VarLengthVar, e.g. `x_i` in [x_1 for i = 1:n]"
immutable IndexedParameter{T} <: ParameterExpr{T}
  name::Symbol
  index::Symbol
end

"Convert an indexed parameter to a normal parameter"
function Parameter{T}(x::IndexedParameter{T}, index::Integer)
  Parameter{T}(symbol(x.name, :_, index))
end

string(x::IndexedParameter) = string(x.name, "_", x.index)

"parameter(s) after transformation, e.g. `2t` or `a+b+5`"
immutable TransformedParameter{T} <: ParameterExpr{T}
  expr::Expr
  function TransformedParameter(expr)
    @assert expr.head == :call || expr.head == :comparison "expr must start with call not $(expr.head)"
    new{T}(expr)
  end
end

string(x::TransformedParameter) = string(x.expr)

"Symbol name for argument (input or output) of arrow"
immutable PortName <: Variable
  name::Symbol
end

string(x::PortName) = string(x.name)

## Model
## =====

"An assignment of values to variables, e.g. [n => 10]"
typealias Model Dict{Variable, Integer}

## Type Arrays: arrays of type expressions
## =======================================

"""A fixed length vector of type expressions and constants"""
immutable FixedLenVarArray
  typs::Tuple{Vararg{ParameterExpr}}
end

length(x::FixedLenVarArray) = length(x.typs)
ndims(x::FixedLenVarArray) = 1
string(x::FixedLenVarArray) = join(map(string, x.typs),", ")

"A vector of variable length of type expressions of `len`, e.g. s:[x_i for i = 1:n]"
immutable VarLenVarArray
  lb::Integer
  ub::ParameterExpr{Integer}
  expr::ParameterExpr
end

"Convert a variable length var array into a fixed length one"
function fix(x::VarLenVarArray, ub::Integer)
  # TODO: Implement for expressions
  typs = [Parameter(x.expr, i) for i = x.lb:ub]
  FixedLenVarArray(tuple(typs...))
end

length(x::VarLenVarArray) = x.ub
ndims(x::VarLenVarArray) = 1
string(x::VarLenVarArray) = string("$(string(x.expr)) for i = $(x.lb):$(string(x.ub))")

"""Datastructures for arrays of type expressions.
They are not not Kinds themselves; just a datastructure used by other Kinds"""
typealias VarArray Union{FixedLenVarArray, VarLenVarArray}
printers(VarArray)

## Kinds
## =====

"All permissible types"
abstract Kind
printers(Kind)

## Array Type : Represent n-dimensional arrays
## ===========================================

"Class of types which represent arrays"
abstract ArrayType <: Kind

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
fix{T}(a::ShapeParams{T}, n::Integer) = ShapeParams{T}(a.portname, fix(a.dimtypes, n))
function fix(a::ShapeParams, model::Model)
  if !isfixeddims(a) && haskey(model, ndims(a))
    @show "got here"
    @show model[ndims(a)]
    fix(a, model[ndims(a)])
  else
    return a
  end
end


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

fix(a::ValueParams, n::Integer) = ValueParams{T}(a.portname, fix(a.values, n))
function fix(a::ValueParams, model::Model)
  if !isfixeddims(akind) && haskey(model, length(a))
    fix(a, model[length(a)])
  else
    return a
  end
end

string(a::ValueParams) = string(string(a.portname)":","[", string(a.values),"]")

## Diemsnion Type
## ==============

typealias VarMap Dict{Variable, Variable}

immutable DimType{I, O} <: Kind
  inptypes::Tuple{Vararg{Parameter{Integer}}}
  outptypes::Tuple{Vararg{Parameter{Integer}}}
  constraints::ConstraintSet
end

"Return a new dimension type with variables substituted"
function substitute(d::DimType, varmap::VarMap)
  error("unimplemented")
end

"Set of unique dimensionality parameters"
function parameters(d::DimType)
  paramset = Set{Parameter}()
  for dtype in vcat(dtyp.inptypes, dtyp.outtypes, dtype.constraints)
    merge!(paramset, parameters(dtype))
  end
  paramset
end

## ArrowType : Represent types of arrow
## ====================================

"""an arrow type represents the type at the input and type of output
These types could be array types, or other arrows types."""
immutable ArrowType{I, O} <: Kind
  inptypes::Tuple{Vararg{Kind}}
  outtypes::Tuple{Vararg{Kind}}
  constraints::ConstraintSet
  function ArrowType(
      inptypes::Tuple{Vararg{Kind}},
      outtypes::Tuple{Vararg{Kind}},
      constraints::ConstraintSet)
    @assert length(inptypes) == I
    @assert length(outtypes) == O
    new{I,O}(inptypes, outtypes, constraints)
  end
  function ArrowType(inptypes::Tuple{Vararg{Kind}},outtypes::Tuple{Vararg{Kind}})
    new{I, O}(inptypes, outtypes, ConstraintSet())
  end
end

"An arrow type"
immutable ArrowTypeDim{I, O} <: Kind
  dimtype::DimType{I,O}
  inptypes::Tuple{Vararg{Kind}}
  outtypes::Tuple{Vararg{Kind}}
  constraints::ConstraintSet

  "Construct DimTypes from Arrowtypes if not given"
  function ArrowTypeDim(
      inptypes::Tuple{Vararg{Kind}},
      outtypes::Tuple{Vararg{Kind}},
      constraints::ConstraintSet)
    @assert length(inptypes) == I
    @assert length(outtypes) == O
    new{I,O}(inptypes, outtypes, constraints)
  end
  function ArrowTypeDim(inptypes::Tuple{Vararg{Kind}},outtypes::Tuple{Vararg{Kind}})
    new{I, O}(inptypes, outtypes, ConstraintSet())
  end
end

function fix{I, O}(a::ArrowType{I, O}, model::Model)
  newinptypes = map(m->(fix(m, model)), a.inptypes)
  newouttypes = map(m->(fix(m, model)), a.outtypes)
  # TODO handle constraints
  newconstraints = a.constraints
  ArrowType{I, O}(newinptypes, newouttypes, newconstraints)
end

function string{I,O}(x::ArrowType{I,O})
  inpstring = string(join(map(string, x.inptypes), ", "))
  outstring = string(join(map(string, x.outtypes), ", "))
  constraints = string(join(map(string, x.constraints), " & "))
  "$inpstring >> $outstring $(!(isempty(constraints)) ? constraints : " ")"
end

#
# ""
# "Return a set of all the variables in this"
# function variables(a::ParaneterExpr)
# end
#
# "Return a set of all the dimension variables in a"
# function dimvariables(a::ParaneterExpr)
# end
# immutable ConstrainedParameter{T} <: ParameterExpr{T}
# immutable IndexedParameter{T} <: Pa
#
# FixedLenVarArray
# VarLengthVar
# ShapeParams
# ValueParams
#
# dimvariables(a::ArrowType) =
#   union(dimvariables(a.inptypes), dimvariables(a.outtypes), dimvariables(a.constraints))
