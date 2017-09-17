curly(x::AbstractString) = string("{",x,"}")
parens(x::AbstractString) = string("(",x,")")
square(x::AbstractString) = string("[",x,"]")

"Generate a unique arrow id"
gen_id()::Symbol = gensym()

"All elements in `xs` are the same?"
function same(xs)::Bool
  if isempty(xs)
    return true
  else
    x1 = first(xs)
    for xn in xs
      if xn != x1
        return false
      end
    end
  end
  return true
end

"`f: coll -> Bool`, such that ∀ x in xs, x ∈ coll"
allin_f(xs) = coll -> all((x ∈ coll for x in xs))

"Given a `partition` return a mapping from elements to the cell (integer id)"
function cell_membership{T}(partition::Vector{Vector{T}})::Dict{T, Int}
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

## Data Structures ##
"`l` s.t. `dict[l] == r`. If many `l` map to `r` output is nondeterminsitic"
function rev{L, R}(dict::Associative{L, R}, r::R)
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
