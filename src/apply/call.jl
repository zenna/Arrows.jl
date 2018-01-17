"Compiles an arrow to a `target`"
function compile(arr::Arrow, target::Target) end

"Adds arrow `arr` and any CompArrows is contains to global new space"
compile!(arr::Arrow) = foreach(eval ∘ pol_to_julia, policies(arr))

function do_compile_module(arr::CompArrow)
  expr = compile(arr)
  codes = expr.args[2].args[1:end-1]
  return_stmt = expr.args[2].args[end]
  names = return_stmt.args[1]
  M = Module()
  eval(M, :(using Arrows))
  for code ∈ codes
    eval(M, :($code))
  end
  eval(M, :($(names)[1]))
end

function do_compile(arr::CompArrow)
  lambda = eval(compile(arr))
  Base.invokelatest(lambda)[1]
end

"Apply `arr(args...)``"
function (arr::CompArrow)(args...)
  f = do_compile_module(arr)
  Base.invokelatest(f, args...)
end


"Convert `arr` into a julia function"
function julia(arr::CompArrow)
  f = do_compile_module(arr)
end
