## Type Hierarchy
## Variable -->
#     ParameteExpr ---> Parameter, TransformedParameter
#     PortName
#     Argument

## Type expressions / variables
## ============================
"Gives names to things which can vary - parameters, port names, type variables"
abstract Variable{T}
printers(Variable)

"An expression for parameters which represent values of type `T`"
abstract ParameterExpr{T} <: Variable{T}

"A parameter used within a parametric type, ranges over values of type `T`"
immutable Parameter{T <: Number} <: ParameterExpr{T}
  name::Symbol  # e.g. x
end

string(x::Parameter) = string(x.name)

## constraints
## ==========

"A set of constraints"
# typealias ConstraintSet Tuple{Vararg{ParameterExpr{Bool}}}
typealias ParameterSet Set{Parameter}
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
  constraint = p >= 0
  ConstrainedParameter{T}(p, ConstraintSet([constraint]))
end

string(c::ConstrainedParameter; withconstraints::Bool = false) =
  string(c.param, !(isempty(c.constraints)) ? string(" | ", string(c.constraints)) : " ")

"An indexed type variable, used in VarLengthVar, e.g. `x_i` in [x_1 for i = 1:n]"
immutable IndexedParameter{T} <: ParameterExpr{T}
  param::Parameter{T}
  index::Symbol
end

IndexedParameter(T::Type, p::Symbol, i::Symbol) =
  IndexedParameter{T}(Parameter{T}(p), i)

"Convert an indexed parameter to a normal parameter"
function Parameter{T}(x::IndexedParameter{T}, index::Integer)
  Parameter{T}(symbol(x.name, :_, index))
end

string(x::IndexedParameter) = string(x.param, "_", x.index)

## PortName
## ========

"Symbol name for argument (input or output) of arrow"
immutable PortName <: Variable
  name::Symbol
end

string(x::PortName) = string(x.name)

## Variable Arithmetic
## ===================

## Transformed Parameter
## =====================
"parameter(s) after transformation, e.g. `2t` or `a+b+5`"
abstract TransformedParameter{T} <: ParameterExpr{T}
string(p::TransformedParameter) =
  string(head(p), "(", join([string(arg) for arg in args(p)], ", "), ")")

# "Return a Set of dimension indices of a random variable"
# function dims(X::Variable)
#   # Do a depth first search and find union of dimensions of all OmegaVars
#   dimensions = Set{Int}()
#   visited = Set{Var}()
#   tovisit = Set{Var}([X])
#   while !isempty(tovisit)
#     v = pop!(tovisit)
#     if has_single_dim(v)
#       push!(dimensions, v.dim)
#     end
#     for arg in args(v)
#       arg ∉ visited && push!(tovisit,arg)
#     end
#   end
#   dimensions
# end
#
# # Base case is that symbolic rand vars have multiple dims
# has_single_dim(X::Variable) = false

function isequal(X::Variable, Y::Variable)
  # Equivalent Random variables should (at least) have same type and #args
  typeof(X) != typeof(Y) && (return false)
  x_args = fields(X)
  y_args = fields(Y)
  length(x_args) != length(y_args) && (return false)
  for i = 1:length(x_args)
    !isequal(x_args[i],y_args[i]) && (return false)
  end
  true
end

# @compat in{T}(X::Variable, bounds::Tuple{Lift{T},Lift{T}}) = (X >= bounds[1]) & (X <=  bounds[2])

## Constant Variable
## =================
"A constant value. A constant function which 'ignores' input, e.g. ω->5"
immutable ConstantVar{T} <: ParameterExpr{T}
  val::T
end

string(x::ConstantVar) = string(x.val)
args(X::ConstantVar) = tuple()

## Real × Real -> Real
## ===================
real_real_real = ((:PlusVar,:+), (:MinusVar,:-), (:TimesVar,:*),
                  (:DivideVar,:/), (:PowVar,:(^)), (:LogVar,:log))
for (name,op) in real_real_real
  eval(
  quote
  immutable $name{T<:Real,A1<:Real,A2<:Real} <: TransformedParameter{T}
    @compat args::Tuple{ParameterExpr{A1}, ParameterExpr{A2}}
  end
  # (^) Fixes ambiguities. Redefined here in each loop iteration but shouldn't matter
  (^){T1<:Real,T2<:Integer}(X::ParameterExpr{T1},c::T2) =
    PowVar{promote_type(T1, T2),T1,T2}((X,ConstantVar(c)))
  ($op){T1<:Real, T2<:Real}(X::ParameterExpr{T1}, Y::ParameterExpr{T2}) =
    $name{promote_type(T1, T2),T1,T2}((X,Y))
  ($op){T1<:Real, T2<:Real}(X::ParameterExpr{T1}, c::T2) =
    $name{promote_type(T1, T2),T1,T2}((X,ConstantVar(c)))
  ($op){T1<:Real, T2<:Real}(c::T1, X::ParameterExpr{T2}) =
    $name{promote_type(T1, T2),T1,T2}((ConstantVar(c),X))
  head(::$name) = $(QuoteNode(op))
  end)
end

# Real -> Real
## ===========
real_real = ((:UnaryPlusVar,:+),(:UnaryMinusVar,:-),(:AbsVar,:abs))
for (name,op) in real_real
  eval(
  quote
  immutable $name{T<:Real, A1<:Real} <: TransformedParameter{T}
    @compat args::Tuple{ParameterExpr{A1}}
  end
  ($op){T<:Real}(X::Variable{T}) = $name{T,T}((X,))
  head(::$name) = $(QuoteNode(op))
  end)
end

# Real -> _<:Floating
## ==================
real_floating = (
  (:SqrtVar, :sqrt), (:ExpVar,:exp), (:SinVar,:sin),
  (:CosVar,:cos), (:TanVar,:tan), (:AsinVar,:asin),
  (:AcosVar,:acos), (:AtanVar,:atan), (:SinhVar,:sinh),
  (:CoshVar,:cosh), (:TanhVar,:tanh), (:Atan2Var,:atan2))

for (name,op) in real_floating
  eval(
  quote
  immutable $name{T<:Real,A1<:Real} <: TransformedParameter{T}
    @compat args::Tuple{ParameterExpr{A1}}
  end
  ($op){T<:Real}(X::ParameterExpr{T}, returntype::DataType = Float64) = $name{returntype,T}((X,))
  head(::$name) = $(QuoteNode(op))
  end)
end

# Real × Real -> Bool
## ===================
real_real_bool = ((:GTVar, :>), (:GTEVar,:>=), (:LTEVar,:<=), (:LTVar,:<),
                  (:EqVar, :(==)), (:NeqVar, :!=))

for (name,op) in real_real_bool
  eval(
  quote
  immutable $name{T<:Real,A1<:Real,A2<:Real} <: TransformedParameter{T}
    @compat args::Tuple{ParameterExpr{A1},ParameterExpr{A2}}
  end
  ($op){T1<:Real, T2<:Real}(X::ParameterExpr{T1}, Y::ParameterExpr{T2}) = $name{Bool,T1,T2}((X,Y))
  ($op){T1<:Real, T2<:Real}(X::ParameterExpr{T1}, c::T2) = $name{Bool,T1,T2}((X,ConstantVar(c)))
  ($op){T1<:Real, T2<:Real}(c::T1, X::ParameterExpr{T2}) = $name{Bool,T1,T2}((ConstantVar(c),X))
  head(::$name) = $(QuoteNode(op))
  end)
end

## Real × Real -> Bool
## ===================
bool_bool_bool = ((:OrVar, :|), (:AndVar,:&), (:BicondVar, :(==)))
for (name,op) in bool_bool_bool
  eval(
  quote
  immutable $name{T,A1,A2} <: TransformedParameter{Bool}
    @compat args::Tuple{ParameterExpr{A1},ParameterExpr{A2}}
  end
  ($op)(X::ParameterExpr{Bool}, Y::ParameterExpr{Bool}) = $name{Bool,Bool,Bool}((X,Y))
  ($op)(X::ParameterExpr{Bool}, c::Bool) = $name{Bool,Bool,Bool}((X,ConstantVar(c)))
  ($op)(c::Bool, X::ParameterExpr{Bool}) = $name{Bool,Bool,Bool}((ConstantVar(c),X))
  head(::$name) = $(QuoteNode(op))
  end)
end

## Bool -> Bool
## ============
immutable NotVar{T,A1} <: TransformedParameter{Bool}
  @compat args::Tuple{Variable{A1}}
end
!(X::ParameterExpr{Bool})= NotVar{Bool,Bool}((X,))
head(::NotVar) = :!

immutable IfElseVar{T,A1,A2,A3} <: ParameterExpr{T}
  @compat args::Tuple{ParameterExpr{A1},ParameterExpr{A2},ParameterExpr{A3}}
end
head(::IfElseVar) = :ifelse

## Ifelse
## ======
ifelse{T}(A::ParameterExpr{Bool}, B::ParameterExpr{T}, C::ParameterExpr{T}) =
  IfElseVar{T,Bool,T,T}((A,B,C))
ifelse{T<:Real}(A::ParameterExpr{Bool}, B::T, C::T) =
  IfElseVar{T,Bool,T,T}((A,ConstantVar(B),ConstantVar(C)))
ifelse{T<:Real}(A::ParameterExpr{Bool}, B::ParameterExpr{T}, C::T) =
  IfElseVar{T,Bool,T,T}((A,B,ConstantVar(C)))
ifelse{T<:Real}(A::ParameterExpr{Bool}, B::T, C::ParameterExpr{T}) =
  IfElseVar{T,Bool,T,T}((A,ConstantVar(B),C))

# Unions
## =====
BinaryRealExpr = Union{PlusVar, MinusVar, TimesVar, DivideVar, PowVar, LogVar}
UnaryRealExpr = Union{UnaryPlusVar,UnaryMinusVar,AbsVar}
TrigExpr = Union{ExpVar,SinVar,CosVar,TanVar,AsinVar,
                 AcosVar,AtanVar,SinhVar,CoshVar,TanhVar,Atan2Var}
IneqExpr = Union{GTVar,GTEVar,LTEVar, LTVar,EqVar,NeqVar}
LogicalExpr = Union{OrVar,AndVar, BicondVar, NotVar}

# All Functional expressions
CompositeVar = Union{BinaryRealExpr, UnaryRealExpr, TrigExpr, IneqExpr,
                     LogicalExpr, SqrtVar, IfElseVar}

args{T<:CompositeVar}(X::T) = X.args

## Model
## =====

typealias VarMap Dict{Variable, Variable}

"An assignment of values to variables, e.g. [n => 10]"
typealias Model Dict{Variable, Integer}

## Parameter Extraction
## ====================

parameters(p::Parameter) = ParameterSet([p])
parameters(p::ConstrainedParameter) = ParameterSet([p.param])
parameters(p::ConstantVar) = ParameterSet()

## Prefixing
## =========

"Turn a parameter `p` into `prefixp`"
prefix{T}(p::Parameter{T}, pfx::Symbol) = Parameter{T}(symbol(pfx, :_, p.name))
prefix{T}(p::ConstrainedParameter{T}, pfx::Symbol) =
  ConstrainedParameter{T}(prefix(p.param, pfx), prefix(p.constraints, pfx))
prefix(cs::ConstraintSet, pfx::Symbol) = ConstraintSet(map(i->prefix(i, pfx), cs))
prefix(c::ConstantVar, pfx::Symbol) = c
prefix{T <: TransformedParameter}(c::T, pfx::Symbol) =
  T(tuple([prefix(arg, pfx) for arg in args(c)]...))
prefix(ps::ParameterSet, pfx::Symbol) = ParameterSet([prefix(p, pfx) for p in ps])

function substitute(d::Parameter, varmap::VarMap)
  if haskey(varmap, d)
    varmap[d]
  else
    error("varmap does not contain parameter $d")
  end
end

"Constrained parameter with parameter replaced accoriding to `varmap`"
function substitute{T}(d::ConstrainedParameter{T}, varmap::VarMap)
  if haskey(varmap, d.param)
    warn("FIXME: not handling constraints")
    ConstrainedParameter{T}(varmap[d.param])
  else
    error("varmap does not contain parameter $d")
  end
end
