## Make it more convenient to construct types
## ==========================================
"x_i -> (x,i), hello_pos -> (hello_pos)"
function namefromindex(x::Symbol)
  x = map(symbol, split(string(x), '_'))
  @assert length(x) == 2 "Only one _ allowed in name"
  x
end

"Is this an index symbol _"
isindexsymbol(x::Symbol) = length(split(string(x), '_')) == 2

function param_gen(x::Symbol, t::DataType; nonneg::Bool = true)
  if isindexsymbol(x)
    args = namefromindex(x)
    :(IndexedParameter(Real, $args...))
  else
    xq = QuoteNode(x)
    nonneg ? :(nonnegparam($t, $xq)) : :(Parameter{$t}($xq))
  end
end

function param_gen(x::Expr, t::DataType)
  xq = Expr(:quote, x)
  :(TransformedParameter{$t}($xq))
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

"Construct a shape parameter, usage: @shape n [x_i for i = 1:n]"
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
    :(ArrowType{$I, $O}($inps, $outs))
  else
    error("inps and outs must be vectors")
  end
end

"Create a dim type. usage: @dimtype [n] [m] [n + m == 10]"
macro dimtype(a, b)
  if a.head == :vect && b.head == :vect
    I = length(a.args)
    O = length(b.args)
    inps = [param_gen(arg, Integer) for arg in a.args]
    inpst = :(tuple($(inps...)))
    outps = [param_gen(arg, Integer) for arg in b.args]
    outpst = :(tuple($(outps...)))
    :(DimType{$I, $O}($inpst, $outpst))
  else
    error("inps and outs must be vectors")
  end
end

macro arrtype2(d, a, b)
  if a.head == :vect && b.head == :vect
    I = length(a.args)
    O = length(b.args)
    inps = Expr(:call, :tuple, map(esc, a.args)...)
    outs = Expr(:call, :tuple, map(esc, b.args)...)
    #TODO handle constraints
    @show :(ArrowType{$I, $O}($(esc(d)), $inps, $outs))
  else
    error("inps and outs must be vectors")
  end
end

## Helpers for making things easy
## ================================
IntOrSymbol = Union{Int, Symbol}
TypeOrSymbol = Union{Type, Symbol}

# Elem
genelemtype(s::Symbol) = ElementParam(Parameter{DataType}(s))
genelemtype{T<:Real}(::Type{T}) =  ElementParam(ConstantVar(T))

"usage: arrowdim((3,:s,:t), (1,2,3)) ==> 3, s⁺, t⁺ >> 1, 2, 3"
function arrowelem(inpelemvars::Tuple{Vararg{TypeOrSymbol}}, outelemvars::Tuple{Vararg{TypeOrSymbol}})
  ArrowParam{length(inpelemvars), length(outelemvars), ElementParam}(
    map(genelemtype, inpelemvars), map(genelemtype, outelemvars), ConstraintSet())
end

# dim
"Construct dimension param `s`"
function nndimp(s::Symbol)
  n = nonnegparam(Integer, s)
  DimParam(n)
end

"Construct dimension param `s`"
function nndimp(s::Integer)
  n = ConstantVar{Integer}(s)
  DimParam(n)
end

"create dimension parameters, e.g. dims = [3,d,1]"
function dimarray(dimvars::Tuple{Vararg{IntOrSymbol}})
  map(nndimp, dimvars)
end

"usage: arrowdim((3,:s,:t), (1,2,3)) ==> 3, s⁺, t⁺ >> 1, 2, 3"
function arrowdim(inpdimvars::Tuple{Vararg{IntOrSymbol}}, outdimvars::Tuple{Vararg{IntOrSymbol}})
  ArrowParam{length(inpdimvars), length(outdimvars), DimParam}(
    dimarray(inpdimvars),dimarray(outdimvars), ConstraintSet())
end

# shape
"Construct dimension param `s`"
function variable(s::Symbol)
  nonnegparam(Integer, s)
end

"Construct dimension param `s`"
function variable(s::Integer)
  ConstantVar{Integer}(s)
end

"create dimension parameters, e.g. dims = [3,d,1]"
function variable(vars::Tuple{Vararg{IntOrSymbol}})
  map(variable, vars)
end

"create dimension parameters, e.g. dims = [3,d,1]"
function flarray(vars::Tuple{Vararg{IntOrSymbol}})
  FixedLenVarArray(variable(vars))
end

"create dimension parameters, e.g. dims = [3,d,1]"
function vlparams(vars::Tuple{Vararg{IntOrSymbol}})
  ValueParams(flarray(vars))
end

"create dimension parameters, e.g. dims = [3,d,1]"
function shpparams(vars::Tuple{Vararg{IntOrSymbol}})
  ShapeParams(flarray(vars))
end

"usage: arrowdim((3,:s,:t), (3,:s,:t)), (1,2,3)) ==> 3, s⁺, t⁺ >> 1, 2, 3"
function arrowshp(inpshpvars::Tuple{Vararg{Tuple{Vararg{IntOrSymbol}}}},
                  outshpvars::Tuple{Vararg{Tuple{Vararg{IntOrSymbol}}}},
                  c = ConstraintSet())
  ArrowParam{length(inpshpvars), length(outshpvars), ShapeParams}(
    map(shpparams,inpshpvars),map(shpparams,outshpvars), c)
end
