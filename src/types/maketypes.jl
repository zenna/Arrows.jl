## Make it more convenient to construct types
## ==========================================
"x_i -> (x,i), hello_pos -> (hello_pos)"
function namefromindex(x::Symbol)
  x = split(string(x), '_')
  @assert length(x) == 2 "Only one _ allowed in name"
  x
end

"Is this an index symbol _"
isindexsymbol(x::Symbol) = length(split(string(x), '_')) == 2

function param_gen(x::Symbol, t::DataType; nonneg::Bool = true)
  if isindexsymbol(x)
    args = namefromindex(x)
    :(IndexedParameter{Real}($args...))
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
