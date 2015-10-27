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
immutable Parameter{T} <: ParameterExpr{T}  # all type variables are integer based
  name::Symbol
end

string(x::Parameter) = string(x.name)

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

"A type variable after transformation, e.g. `2T`"
immutable CompositeParameter{T} <: ParameterExpr{T}
  expr::Expr
end

string(x::CompositeParameter) = string(x.expr)

"Symbol name for argument (input or output) of arrow. TODO:Maybe rename"
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
  ub::Parameter{Integer}
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

## ArrowType : Represent types of arrow
## ====================================

"""Differentiable arrows take as input a collection of real valued arrays
 and output a collection of real valued a rray"""
immutable ArrowType{I, O} <: Kind
  inptypes::Tuple{Vararg{Kind}}
  outtypes::Tuple{Vararg{Kind}}
  constraints::Vector{ParameterExpr{Bool}}
  function ArrowType(
      inptypes::Tuple{Vararg{Kind}},
      outtypes::Tuple{Vararg{Kind}},
      constraints)
    @assert length(inptypes) == I
    @assert length(outtypes) == O
    new{I,O}(inptypes, outtypes, constraints)
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
# - write convention

## Macros: make it more convenient to construct types
## ==================================================

"x_i -> (x,i), hello_pos -> (hello_pos)"
function namefromindex(x::Symbol)
  x = split(string(x), '_')
  @assert length(x) == 2 "Only one _ allowed in name"
  x
end

"Is this an index symbol _"
isindexsymbol(x::Symbol) = length(split(string(x), '_')) == 2

function param_gen(x::Symbol, t::DataType)
  if isindexsymbol(x)
    args = namefromindex(x)
    :(IndexedParameter{Real}($args...))
  else
    xq = QuoteNode(x)
    :(Parameter{$t}($xq))
  end
end

function param_gen(x::Expr, t::DataType)
  xq = Expr(:quote, x)
  :(CompositeParameter{$t}($xq))
end

function arg_gen(x::Symbol)
  xq = QuoteNode(x)
  :(PortName($xq))
end

function parseparamarray(x::Expr)
  args = map(i->param_gen(i, Integer), x.args)
  # args
  tupled = Expr(:call, :tuple, args...)
  # tupled
  :(FixedLenVarArray($tupled))
end

function parsecomprehension(x::Expr)
  xs = param_gen(x.args[1], Integer)

  @assert x.args[2].head == :(=) "Can't parse array"
  index_symb::Symbol = x.args[2].args[1]

  # parse range 1:n
  rangeexpr::Expr = x.args[2].args[2]
  @assert rangeexpr.head == :(:)
  lb = rangeexpr.args[1]
  ub = rangeexpr.args[2]
  :(VarLenVarArray($lb, $(param_gen(ub, Integer)), $xs))
end

function atype(name, x)
  if x.head == :vect
    body = parseparamarray(x)
  elseif x.head == :comprehension
    body = parsecomprehension(x)
  else
    error("Cannot parse as fixed length var array")
  end
end

macro shape(name, x)
  name = arg_gen(name)
  body = atype(name, x)
  :(ShapeParams{Real}($name, $body))
end

macro intparams(name, x)
  name = arg_gen(name)
  body = atype(name, x)
  :(ValueParams($name, $body))
end

macro arrtype(a, b)
  if a.head == :vect && b.head == :vect
    I = length(a.args)
    O = length(b.args)
    inps = Expr(:call, :tuple, map(esc, a.args)...)
    outs = Expr(:call, :tuple, map(esc, b.args)...)
    #TODO handle constraints
    :(ArrowType{$I, $O}($inps, $outs, []))
  else
    error("inps and outs must be vectors")
  end
end
