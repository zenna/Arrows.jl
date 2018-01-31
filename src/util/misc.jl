"""Convenience macro for requiring keyword arguments

```jldoctest
julia> f(x; @req(y), z = 3) = x + y + z
f (generic function with 2 methods)

julia> f(3)
ERROR: ArgumentError: y is required kwarg
Stacktrace:
 [1] f(::Int64) at ./REPL[29]:1

julia> f(3, y=2)
8
```
"""
macro req(kwd::Symbol)
  skwd = "$kwd is required kwarg"
  argerror = :(throw(ArgumentError($(esc(skwd)))))
  Expr(:kw, kwd, argerror)
end


"""(Partial) inverse of `vcat`

```jldoctest
julia> invvcat([1,2,3,4,5,6], 3)
([1, 2, 3], [4, 5, 6])
```
"""
invvcat(xs, i::Integer) = (@pre 0 < i < length(xs); (xs[1:i], xs[i+1:end]))

"""Split `A` along `dim`, returning size(A)[dim] arrays

```jldoctest
julia> A = reshape(1:20, 5,4)
5×4 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:
 1   6  11  16
 2   7  12  17
 3   8  13  18
 4   9  14  19
 5  10  15  20

 julia> splitdim(A,1)
 5-element Array{Array{Int64,1},1}:
  [1, 6, 11, 16] 
  [2, 7, 12, 17] 
  [3, 8, 13, 18] 
  [4, 9, 14, 19] 
  [5, 10, 15, 20]
```` 
"""
function splitdim(A::AbstractArray, dim::Integer)
  @pre dim <= ndims(A)
  [A[(i == dim ? slice : Colon() for i = 1:ndims(A))...] for slice = 1:size(A)[dim]]
end

"function which splats inputs to `f`"
splat(f) = xs -> f(xs...)

curly(x::AbstractString) = string("{",x,"}")
parens(x::AbstractString) = string("(",x,")")
square(x::AbstractString) = string("[",x,"]")

"Generate a unique arrow id"
gen_id()::Symbol = gensym()

"All elements in `xs` are the same?"
function same(xs, eq=(==))::Bool
  if isempty(xs)
    return true
  else
    x1 = first(xs)
    for xn in xs
      if !(eq(xn, x1))
        return false
      end
    end
  end
  return true
end

"Like `find` but return elements of A instead of ids"
function finditems(f, A)
  idxs = find(f, A)
  [A[idx] for idx in idxs]
end

"Find a unique name `(nn ∉ nms)` - generates `x, x1, x2,..` until ∉ nms"
function uniquename(x::Symbol, nms::Vector{Symbol})
  names = Set(nms)
  nm = x
  i = 1
  while nm ∈ names
    nm = Symbol(x, i)
    i += 1
  end
  nm
end

"Does `xs` contain any element more than once"
hasduplicates(xs) = length(unique(xs)) != length(xs)

"Split a collection `xs` by a predicate"
function partition(pred, xs::Vector{T}) where T
  in = T[]
  out = T[]
  foreach(x -> pred(x) ? push!(in, x) : push!(out, x), xs)
  (in, out)
end

"`f: coll -> Bool`, such that ∀ x in xs, x ∈ coll"
allin_f(xs) = coll -> all((x ∈ coll for x in xs))

"Given a `partition` return a mapping from elements to the cell (integer id)"
function cell_membership(partition::Vector{Vector{T}})::Dict{T, Int} where T
  element_to_class = Dict{T, Int}()
  for (i, class) in enumerate(partition), element in class
    @assert element ∉ keys(element_to_class)
    element_to_class[element] = i
  end
  element_to_class
end

"If (x, y) if p(x) else (y, x)"
function switch(p, x, y)
  if p(x)
    @assert !p(y)
    x, y
  else
    @assert p(y)
    y, x
  end
end

"`l` s.t. `dict[l] == r`. If many `l` map to `r` output is nondeterminsitic"
function rev(dict::Associative{L, R}, r::R) where {L, R}
  for (k, v) in dict
    if v == r
      return k
    end
  end
  throw(KeyError(r))
end

"fgh(f, g, q) = h(f(x), g(x))"
fgh(f, g, h) = x -> h(f(x), g(x))

"""Conjoin predicates
  p = iseven ∧ (x -> x > 0) ∧ (x -> x < 100)
  p(50)
"""
function conjoin(preds::Vararg{Function})
  function pred_conjunct(x...)
    for pred in preds
      if !pred(x...)
        return false
      end
    end
    true
  end
  pred_conjunct
end

"`conjoin` \wedge"
∧ = conjoin

"""Disjoin predicates
  p = iseven ∨ (x -> x > 0) ∨ (x -> x < 100)
"""
function disjoin(preds::Vararg{Function})
  function pred_disjunct(x...)
    for pred in preds
      if pred(x...)
        return true
      end
    end
    false
  end
  pred_disjunct
end

"`disjoin` \vee"
∨ = disjoin

product(::Type{Bool}, n::Integer) = product((true, false), n)

"Product of `n` copies of `xs`: `xs₁ × xs₂ × ⋯ × xsₙ`"
product(xs, n::Integer) = Iterators.product([xs for i = 1:n]...)

"Get type of first param of unary method"
function firstparam(m::Method)
  m.sig.parameters[2]
end

"""Apply every method in`f` applicable to x:T; acccumulate all results
# Arguments
- `f: x::T -> y::T`
# Returns
- [method(x) for method in f if f(::T) exists]
"""
function accumapply(f::Function, x::T) where T
  allmethods = methodswith.(T, f, true)
  results = map(mthd -> invoke(f, Tuple{firstparam(mthd)}, x), allmethods)
end

"mod.s = val"
setinmod!(s::Symbol, val, mod=Main) = eval(mod, :($s = $val))

"Global capture into Main

```
function f(x)
  x = 2x + 3
  @grab x
  y = 3x*2
end

x_grab
"
macro grab(var::Symbol)
  @show var
  grabname = Symbol(var, :_grab)
  :(setinmod!($(Meta.quot(grabname)), $(esc(var))))
end

"""Global capture into Main

```jldoctest
julia> function f(x)
         @grab x = 2x + 3
         y = 3x*2
       end
f (generic function with 1 method)

julia> f(10)
138

julia> x_grab
23
````
x_grab
"""
macro grab(assignexpr::Expr)
  @pre assignexpr.head == :(=) "Must be assignment expression"
  var = assignexpr.args[1]
  grabname = Symbol(var, :_grab)
  quote
    $(esc(assignexpr))
    setinmod!($(Meta.quot(grabname)), $(esc(var)))
  end
end