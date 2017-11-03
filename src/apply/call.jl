"Compiles an arrow to a `target`"
function compile(arr::Arrow, target::Target) end

"Adds arrow `arr` and any CompArrows is contains to global new space"
compile!(arr::Arrow) = foreach(eval ∘ pol_to_julia, policies(arr))

function do_compile(arr::CompArrow)
  lambda = eval(compile(arr))
  Base.invokelatest(lambda)[1]
end

"Apply `arr(args...)``"
function (arr::CompArrow)(args...)
  f = do_compile(arr)
  Base.invokelatest(f, args...)
end

"Convert `arr` into a julia function"
function julia(arr::CompArrow)
  f = do_compile(arr)
end
