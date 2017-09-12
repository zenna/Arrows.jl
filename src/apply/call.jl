compile(arr::Arrow) = JuliaTarget.exprs(arr)

"Adds arrow `arr` and any CompArrows is contains to global new space"
compile!(arr::Arrow) = foreach(eval ∘ pol_to_julia, policies(arr))

function do_compile(arr::CompArrow)
  lambda = eval(compile(arr))
  Base.invokelatest(lambda)[1]
end

"Apply `arr(args...)"
function (arr::CompArrow)(args...)
  f = do_compile(arr)
  Base.invokelatest(f, args...)
end

function julia(arr::CompArrow)
  f = do_compile(arr)
end
