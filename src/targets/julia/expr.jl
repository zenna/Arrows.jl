## Compilation of Arrows to Exprs ##

import Base: broadcast

# This is a hack
broadcast(x::Symbol) = Symbol(:., x)

# By default use the `name` of `carr` as its julia equivalent
function call_expr(arr::PrimArrow, args...)
  if Arrows.  isscalar(arr)
    sizes = map(arg->Expr(:call, :size, arg), args)
    @show sizes
    expr1 = Expr(:call, :println, "SIZES!!!", sizes...)
    expr2 = Expr(:., name(arr), Expr(:tuple, args...))
    Expr(:block, expr1, expr2)
  else
    Expr(:call, name(arr), args...)
  end
end

function call_expr(arr::CompArrow, args...)
  Expr(:call, name(arr), args...)
end
# But we have some special cases
call_expr{N}(arr::DuplArrow{N}, arg) = Expr(:call, dupl, arg, N)
call_expr{N}(arr::InvDuplArrow{N}, args...) = Expr(:call, inv_dupl, args...)
call_expr(arr::SourceArrow, args...) = arr.value

function func_decl_expr(carr::CompArrow)
  funcname = name(carr)
  argnames = map(name, Arrows.in_values(sub_arrow(carr)))
  Expr(:call, funcname, argnames...)
end

function func_return_expr(carr::CompArrow)
  coutnames = map(name, Arrows.out_values(sub_arrow(carr)))
  retargs = if length(coutnames) == 1
    coutnames[1]
  else
    Expr(:tuple, coutnames...)
  end
  ret = Expr(:return, retargs)
end

"Assign expression"
function assign_expr(sarr::SubArrow, outnames::Vector, args...)
  outnames = map(name, tuple(Arrows.out_values(sarr)...))
  lhs = if length(outnames) == 1
    outnames[1]
  else
    Expr(:tuple, outnames...)
  end
  rhs = call_expr(deref(sarr), args...)
  Expr(:(=), lhs, rhs)
end

"The full function expression"
function function_expr(carr::CompArrow, assigns::Vector{Expr})
  decl = func_decl_expr(carr)
  ret = func_return_expr(carr)
  funcblock = Expr(:block, assigns..., ret)
  Expr(:function, decl, funcblock)
end

"Compile `arr` into an `Expr`"
function expr(carr::CompArrow)
  assigns = Vector{Expr}()
  function f(sarr::SubArrow, args)
    outnames = map(name, Arrows.out_values(sarr))
    assign = assign_expr(sarr, outnames, args...)
    push!(assigns, assign)
    outnames
  end

  inputs = map(name, Arrows.in_values(sub_arrow(carr)))
  interpret(f, carr, inputs)
  function_expr(carr, assigns)
end

"Recursively compile `carr` and all arrows it contains into `Expr`s"
function exprs(carr::CompArrow)
  names = []
  name_codes = Arrows.maprecur(carr) do scarr
    (name(scarr), expr(scarr))
  end
  names = map(x->x[1], name_codes)
  codes = map(x->x[2], name_codes)
  ret = Expr(:return, Expr(:tuple, names...))
  block = Expr(:block, codes..., ret)
  Expr(:function, :(()), block)
end
