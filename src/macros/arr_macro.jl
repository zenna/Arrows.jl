# We want to transform functions like this one:
# @arr function f(x::Int, y::Int)
#   2x + y
# end
using MacroTools
import Base: getindex, setindex!

mutable struct DictProxy
  old_context::Dict
  new_context::Dict
  modified::Set
  function DictProxy(context)
    c = new()
    c.old_context = context
    c.new_context = Dict()
    c.modified = Set()
    c
  end
end

function setindex!(dict::DictProxy, value, key)
  push!(dict.modified, key)
  dict.new_context[key] = value
end

function getindex(dict::DictProxy, key)
  if haskey(dict.new_context, key)
    dict.new_context[key]
  else
    dict.old_context[key]
  end
end



""" Evaluate the arguments of the call and then apply the function to the result
of the evaluation. If the evaluation return a `sub_port` or a
`Vector{SubPort}`, the called function should support the overloading."""
function transform_call!(expr, context, carr, in_block::Bool = false)
  args = map(expr->transform_expr!(expr, context, carr), expr.args[2:end])
  name = expr.args[1]
  if name == :(==)
    eq = add_sub_arr!(carr, EqualArrow())
    args[1] ⥅ (eq, 1)
    args[2] ⥅ (eq, 2)
    ◃(eq, 1)
  else
    new_expr = Expr(:call, name, args...)
    eval(new_expr)
  end
end

"Evaluate each element of the block and return the result of the last one"
function transform_block!(block, context, carr, in_block::Bool = false)
  f = expr -> transform_expr!(expr, context, carr, true)

  map(f, block.args[1:end-1])
  transform_expr!(block.args[end], context, carr, in_block)
end

"Assigns to variable `dst` the result of evaluating `src`"
function transform_assignment!(expr, context, carr, in_block::Bool = false)
  dst = expr.args[1]
  @assert isexpr(dst, Symbol)
  src = transform_expr!(expr.args[2], context, carr)
  context[dst] = src
end

"Transform a `Literal` of type `Number` in a `SourceArrow`"
function transform_number!(number, context, carr, in_block::Bool = false)
  parr = SourceArrow(number)
  sarr = add_sub_arr!(carr, parr)
  ◃(sarr, 1)
end

function transform_expr!(expr, context, carr, in_block::Bool = false)
  transform_expr_prim!(MacroTools.unblock(expr), context, carr, in_block)
end

"helper to add an `IfElseArrow`"
function add_if_else(carr, cond, true_clause, false_clause)
  if_arr = Arrows.IfElseArrow()
  sarr = add_sub_arr!(carr, if_arr)
  cond ⥅ (sarr, 1)
  true_clause ⥅ (sarr, 2)
  false_clause ⥅ (sarr, 3)
  ◃(sarr, 1)
end

"Transform `if` and the operator `:?`"
function transform_if!(expr, context, carr, in_block::Bool = false)
  true_context = DictProxy(context)
  false_context = DictProxy(context)
  cond = transform_expr_prim!(expr.args[1], context, carr)
  true_clause = transform_expr_prim!(expr.args[2], true_context, carr)
  false_clause = transform_expr_prim!(expr.args[3], false_context, carr)
  for dst in (true_context.modified ∪ false_context.modified)
    true_value = true_context[dst]
    false_value = false_context[dst]
    context[dst] = add_if_else(carr, cond, true_value, false_value)
  end
  if !in_block
    add_if_else(carr, cond, true_clause, false_clause)
  end
end

"""Recursive function to transform expressions into `SubPort` operations.
`in_block` variable are used to notify that the statement's return value
may not be used."""
function transform_expr_prim!(expr, context, carr, in_block::Bool = false)
  if isexpr(expr, :call)
    transform_call!(expr, context, carr, in_block)
  elseif isexpr(expr, :(=))
    transform_assignment!(expr, context, carr, in_block)
  # elseif isexpr(expr, :->)
  #   transform_lambda!(epxr, context, carr, in_block)
  elseif isexpr(expr, :block)
    transform_block!(MacroTools.rmlines(expr), context, carr, in_block)
  elseif isexpr(expr, :if)
    transform_if!(expr, context, carr, in_block)
  elseif isexpr(expr, Number)
    transform_number!(expr, context, carr, in_block)
  elseif isexpr(expr, Symbol)
    context[expr]
  else
    dump(expr)
    throw(DomainError())
  end
end

"helper from `MacroTools::master`"
splitvar(arg) =
      @match arg begin
          ::T_ => (nothing, T)
          name_::T_ => (name::Symbol, T)
          x_ => (x::Symbol, :Any)
      end


"""Extract information about the function, creates a `CompArrow` and transform
   the `Expr` recursively"""
function transform_function(expr)
  @capture(MacroTools.longdef(expr), function  (fcall_ | fcall_) body_ end)
  @capture(fcall, ((func_(args__; kwargs__)) |
                                    (func_(args__; kwargs__)::rtype_) |
                                    (func_(args__)) |
                                    (func_(args__)::rtype_)))
  args = [splitvar(var)[1] for var in args]                                  
  args = [Symbol(s) for s in args]
  name = Symbol(args...)
  carr = CompArrow(name, args, [:z])
  sports = sub_ports(carr)
  z = sports[end]
  context = Dict([k=> v for (k,v) in zip(args, sports[1:end-1])])
  osprt = transform_expr!(body, context, carr)
  osprt ⥅ z
  carr
end


macro arr(expr)
  let quoted_expr = Expr(:quote, expr)
    :(Arrows.transform_function($(quoted_expr)), eval($(expr)))
  end
end
