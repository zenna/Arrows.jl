## Expr ##
call_expr{N}(arr::DuplArrow{N}, arg) = Expr(:call, dupl, arg, N)
call_expr{N}(arr::InvDuplArrow{N}, args...) = Expr(:call, inv_dupl, args...)
call_expr(arr::SourceArrow, args...) = arr.value
call_expr(arr::Arrow, args...) = Expr(:call, name(arr), args...)

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

"Assign expressio"
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
  if length(assigns) > 1000
    funcblock = function_splits(assigns, name(carr))
  else
    funcblock = Expr(:block, assigns..., ret)
  end
  Expr(:function, decl, funcblock)
end

"""When a function contains many statements, it's more efficient to split
them in smaller functions"""
function function_splits(assigns, name)
  answer = []
  n = length(assigns)
  k = 400
  for i in 1:k:n
    chunk = assigns[i:min(i+k-1, n)]
    split_name =  Symbol(name, :__split_, i)
    def, call = process_chunk(chunk, split_name)
    push!(answer, def, call)
  end
  Expr(:block, answer...)
end

function process_chunk(assigns, name)
  # XXX implicit precondition: no variable reuse
  function process_outputs(assigns)
    outputs = []
    for assign in assigns
      output = assign.args[1]
      if isa(output, Expr)
        push!(outputs, output.args...)
      else
        push!(outputs, output)
      end
    end
    outputs
  end
  function process_inputs(assigns, out)
    outputs = Set(out)
    inputs = Set()
    for assign in assigns
      call = assign.args[2]
      if isa(call, Expr) && call.head == :call
        args = Set(call.args[2:end])
        new = setdiff(args, outputs)
        push!(inputs, args...)
      end
    end
    collect(inputs)
  end
  outputs = process_outputs(assigns)
  inputs = process_inputs(assigns, outputs)
  decl = Expr(:call, name, inputs...)
  ret = Expr(:return, Expr(:tuple, outputs...))
  def = Expr(:function, decl, Expr(:block, assigns..., ret))
  call = Expr(:(=), Expr(:tuple, outputs...), decl)
  def, call
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
