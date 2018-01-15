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

"Global capture"
macro grab(var)
  @show var
  grabname = Symbol(var, :_grab)
  :(global $grabname = $(esc(var)))
end
