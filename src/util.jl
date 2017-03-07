curly(x::AbstractString) = string("{",x,"}")
parens(x::AbstractString) = string("(",x,")")
square(x::AbstractString) = string("[",x,"]")


"All elements in xs are the same?"
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
