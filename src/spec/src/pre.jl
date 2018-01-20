"Most recently created method of generic function `func`"
newestmethod(func::Function) = sort(methods(func).ms, by=m->m.min_world)[end]

# macro testing(args...)
#   @show [typeof(arg) for arg in args]
# end
#
# @testing x + 1 ArgumentError("msg") x / 3
PRE_CHECKING_ON = false

"Check preconditions"
pre_check_on!() = (global PRE_CHECKING_ON=true)
pre_check_off!() = (global PRE_CHECKING_ON=false)
pre_check()::Bool = (global PRE_CHECKING_ON; PRE_CHECKING_ON::Bool)

"""
Activate precondition checking within scope of expr

```jldoctest
julia> f(x::Real) = (@pre x > 0; sqrt(x) + 5)
f (generic function with 1 method)

julia> f(-3)
ERROR: DomainError:
Stacktrace:
 [1] f(::Int64) at ./REPL[2]:1

julia> @with_pre begin
               f(-3)
             end
ERROR: ArgumentError: x > 0
Stacktrace:
```
"""
macro with_pre(expr)
  quote
    try
      pre_check_on!()
      $(esc(expr))
      pre_check_off!()
    catch e
      pre_check_off!()
      rethrow(e)
    end
  end
end

"""
Define a precondition on function argument.
Currently `@pre` works similarly to `@assert` except that:
 1) an exception is thrown
 2) pre_check_ons can be disabled

```jldoctest
julia> f(x::Real) = (@pre x > 0; sqrt(x) + 5)
f (generic function with 1 method)

julia> f(-3)
ERROR: ArgumentError: x > 0
```

"""
macro pre(pred)
  strpred = string(pred)
  quote
    if pre_check()
      if !$(esc(pred))
        throw(ArgumentError($strpred))
      end
    end
  end
end


"Define invariant - currently a dummy for documenation"
macro invariant(args...)
end
