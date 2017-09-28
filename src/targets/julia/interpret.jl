## Interpret ##

interpret(::DivArrow, x, y) = (x ./ y,)
function interpret{T}(::MulArrow, x, y::Array{T, 0})
  (x * y[1],)
end
function interpret(::MulArrow, x, y)
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
interpret(::CosArrow, x) = (cos(x),)
interpret(::ModArrow, x, y) = (x .% y,)
interpret(::FloorArrow, x) = (floor(x),)
interpret(::CeilArrow, x) = (ceil(x),)
interpret(::Arrows.MeanArrow, args...) = mean(args...)


function interpret(::GatherNdArrow, params::Array, indices::Array{<:Integer})
  # convert from TensorFlow array indexing!
  indices = indices + 1
  ([params[indices[rr,:]...] for rr in CartesianRange(size(indices)[1:end-1])],)
end
interpret(::NegArrow, x) = (-x,)

## Expr ##
expr(arr::SourceArrow, args...) = arr.value
expr(arr::Arrow, args...) = Expr(:call, name(arr), args...)

sub_interpret(sarr::SubArrow, xs::Vector) = sub_interpret(deref(sarr), xs)
sub_interpret(parr::PrimArrow, xs::Vector) = JuliaTarget.interpret(parr, xs...)
sub_interpret(carr::CompArrow, xs::Vector) = Arrows.interpret(sub_interpret, carr, xs)
