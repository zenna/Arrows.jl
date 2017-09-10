function compile(arr::Arrow)
  pols = policies(arr)
  codes = pol_to_julia.(pols)
  names = map(name ∘ arrow, pols)
  ret = Expr(:return, Expr(:tuple, names...))
  block = Expr(:block, codes..., ret)
  expr = Expr(:function, :(()), block)
  expr
end

"Adds arrow `arr` and any CompArrows is contains to global new space"
compile!(arr::Arrow) = foreach(eval ∘ pol_to_julia, policies(arr))

"Apply `arr(args...)"
function (arr::CompArrow)(args...)
  f = do_compile(arr)
  Base.invokelatest(f, args...)
end

function do_compile(arr::CompArrow)
  lambda = eval(compile(arr))
  Base.invokelatest(lambda)[1]
end

function julia(arr::CompArrow)
  f = do_compile(arr)
end
