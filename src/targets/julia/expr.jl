## Expr ##
call_expr(arr::SourceArrow, args...) = arr.value
call_expr(arr::Arrow, args...) = Expr(:call, name(arr), args...)

function func_decl_expr(carr::CompArrow)
  funcname = name(carr)
  argnames = map(name, Arrows.in_values(sub_arrow(carr)))
  Expr(:call, funcname, argnames...)
end

function func_return_expr(carr::CompArrow)
  coutnames = map(name, Arrows.out_values(sub_arrow(carr)))
  retargs = Expr(:tuple, coutnames...)
  ret = Expr(:return, retargs)
end

"Assign expressio"
function assign_expr(sarr::SubArrow, outnames::Vector, args...)
  outnames = map(name, tuple(Arrows.out_values(sarr)...))
  lhs = Expr(:tuple, outnames...)
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
