
module JuliaTarget

function convert(::Type{Expr}, x::CallExpr)
  Expr(:(=), Expr(:tuple, x.outputsymbs...), Expr(:call, x.f, x.inputsymbs...))
end

function convert(::Type{Expr}, f::FuncDef)
  header = Expr(:call, f.f, [:($x::Array{Float64}) for x in f.inputsymbs]...)
  ret = Expr(:return, Expr(:tuple, [x for x in f.outputsymbs]...))
  code = Expr(:block, [convert(Expr, fcall) for fcall in f.calls]..., ret)
  Expr(:function, header, code)
end

end
