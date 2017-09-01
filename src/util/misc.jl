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
