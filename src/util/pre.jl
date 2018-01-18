"Most recently created method of generic function `func`"
newestmethod(func::Function) = sort(methods(func).ms, by=m->m.min_world)[end]

# macro testing(args...)
#   @show [typeof(arg) for arg in args]
# end
#
# @testing x + 1 ArgumentError("msg") x / 3

const PRE_CHECKING_ON = false

"Check preconditions"
pre_check!() = (global PRE_CHECKING_ON; PRE_CHECKING_ON=true)
no_check!() = (global PRE_CHECKING_ON; PRE_CHECKING_ON=false)

"""
Temporarily activate precondition checking

```jldoctest
julia> f(x::Real) (@pre x > 0; sqrt(x) + 5)

@with_pre do
  f(-3)
end
```
"""
macro with_pre(expr)
  quote
    pre_check!()
    $expr
    no_check!()
  end
end

"""
Precondition

```jldoctest
julia> f(x::Real) (@pre x > 0; sqrt(x) + 5)
```


"""
macro pre(pred)
  quote
    if PRE_CHECKING
      if !$pred
        throw(ArgumentError($pred))
      end
    end
  end
end


"Define invariant - currently a dummy for documenation"
macro invariant(args...)
end
