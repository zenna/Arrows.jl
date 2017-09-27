# We want to transform functions like this one:
# @arr function f(x::Int, y::Int)
#   2x + y
# end



@arr function f(x::Int, y::Int)
   x*y + y
 end


function transform_call!(expr, context, carr)
   args = map(expr->transform_expr!(expr, context, carr), expr.args[2:end])
   name = expr.args[1]
   if name == :*
      sarr = add_sub_arr!(carr, MulArrow())
   elseif name == :+
      sarr = add_sub_arr!(carr, AddArrow())
   else
      throw(DomainError())
   end
   @assert length(args) == 2
   args[1] ⥅▹(sarr, 1)
   args[2] ⥅▹(sarr, 2)
   ◃(sarr, 1)
end

function transform_block(block, context, carr)
   for expr in block.args
      transform_expr!(expr, context, carr)
   end
end

function transform_expr!(expr, context, carr)
   if isexpr(expr, :call)
      transform_call!(expr, context, carr)
   elseif isexpr(expr, :(=))
      transform_assigment!(expr, context, carr)
   elseif isexpr(expr, :->)
      transform_lambda!(epxr, context, carr)
   elseif isexpr(expr, Symbol)
      context[expr]
   elseif isexpr(expr, :block)
      transform_block!(MacroTools.rmlines(expr), context, carr)
   else
      throw(DomainError())
   end
end



function transform_function(expr)
   carr = CompArrow(:xyx, [:x, :y], [:z])
   x, y, z = ports(carr)
   context = Dict([:x => x, :y => y])
   @capture(MacroTools.longdef(expr), function (fcall_1 | fcall_) body_ end)
   body = MacroTools.unblock(body)
   osprt = transform_expr!(body, context, carr)
   osprt ⥅ z
   carr
end


# thread(x, ex) =
#     isexpr(ex, :call, :macrocall) ? Expr(ex.head, ex.args[1], x, ex.args[2:end]...) :
#     isexpr(ex, :block)            ? thread(x, rmlines(ex).args...) :
#     Expr(:call, ex, x)
