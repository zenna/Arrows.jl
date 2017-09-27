# We want to transform functions like this one:
# @arr function f(x::Int, y::Int)
#   2x + y
# end


function transform_call!(expr, context, carr)
   args = map(expr->transform_expr!(expr, context, carr), expr.args[2:end])
   name = expr.args[1]
   if name == :*
      parr = MulArrow()
   elseif name == :+
      parr = AddArrow()
   else
      throw(DomainError())
   end
   sarr = add_sub_arr!(carr, parr)
   @assert length(args) == 2
   args[1] ⥅▹(sarr, 1)
   args[2] ⥅▹(sarr, 2)
   ◃(sarr, 1)
end

function transform_block!(block, context, carr)
   f = expr -> transform_expr!(expr, context, carr)
   map(f, block.args)[end]
end

function transform_assigment!(expr, context, carr)
   dst = expr.args[1]
   dump(dst)
   @assert isexpr(dst, Symbol)
   src = transform_expr!(expr.args[2], context, carr)
   context[dst] = src
end

function transform_number!(number, context, carr)
   parr = SourceArrow(number)
   sarr = add_sub_arr!(carr, parr)
   ◃(sarr, 1)
end

function transform_expr!(expr, context, carr)
   transform_expr_prim!(MacroTools.unblock(expr), context, carr)
end

function transform_expr_prim!(expr, context, carr)
   if isexpr(expr, :call)
      transform_call!(expr, context, carr)
   elseif isexpr(expr, :(=))
      transform_assigment!(expr, context, carr)
   elseif isexpr(expr, :->)
      transform_lambda!(epxr, context, carr)
   elseif isexpr(expr, :block)
      transform_block!(MacroTools.rmlines(expr), context, carr)
   elseif isexpr(expr, Number)
      transform_number!(expr, context, carr)
   elseif isexpr(expr, Symbol)
      context[expr]
   else
      throw(DomainError())
   end
end



function transform_function(expr)
   carr = CompArrow(:xyx, [:x, :y], [:z])
   x, y, z = sub_ports(carr)
   context = Dict([:x => x, :y => y])
   @capture(MacroTools.longdef(expr), function (fcall_1 | fcall_) body_ end)
   osprt = transform_expr!(body, context, carr)
   osprt ⥅ z
   carr
end
