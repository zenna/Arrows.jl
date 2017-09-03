interpret(::DivArrow, x, y) = (x ./ y,)
function interpret{T}(::MulArrow, x, y::Array{T, 0})
  @show size(x) size(y[1])
  (x * y[1],)
end
function interpret(::MulArrow, x, y)
  @show size(x) size(y)
  (x .* y,)
end
interpret(::SubtractArrow, x, y) = (x .- y,)
interpret(::AddArrow, x, y) = (x .+ y,)
interpret(::EqualArrow, x, y) = (x == y,)
interpret(::CondArrow, i, t, e) = ((i ? t : e),)
interpret(arr::SourceArrow) = (arr.value,)
interpret(::IdentityArrow, x) = (x,)
interpret(::ExpArrow, x) = (exp(x),)
interpret(::SinArrow, x) = (sin(x),)

function interpret(::GatherNdArrow, params::Array, indices::Array{<:Integer})
  # convert from TensorFlow array indexing!
  indices = indices + 1
  ([params[indices[rr,:]...] for rr in CartesianRange(size(indices)[1:end-1])],)
end
interpret(::NegArrow, x) = (-x,)
