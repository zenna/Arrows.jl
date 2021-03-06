"Duplicates input `I` times dupl_n_(x) = (x,...x)"
struct InvDuplArrow{I} <: PrimArrow end

props(::InvDuplArrow{I}) where I=
  [[Props(true, Symbol(:x, i), Array{Any}) for i=1:I]...,
   Props(false, :y, Array{Any})]

name(::InvDuplArrow{I}) where I = Symbol(:inv_dupl_, I)
InvDuplArrow(n::Integer) = InvDuplArrow{n}()
abinterprets(::InvDuplArrow) = [sizeprop]

"f(x, x) = (x,)"
function inv_dupl(xs...)
  @assert !any(x->isa(x, AbstractArray), xs)
  same(xs, ≈) || throw(ArgumentError("All inputs to invdupl should be same $xs"))
  first(xs)
end

function inv_dupl(xs::AbstractArray...)
  ## TODO: Simplify!
  base = first(xs)
  answer = similar(base)
  err = "All inputs to invdupl should have the same size $(size.(xs))"
  size_base = size(base)
  all(i-> size(i) == size_base, xs) || throw(ArgumentError(err))
  every = zip(map(eachindex, xs)..., eachindex(answer))
  pred = map(x->(i->isassigned(x, i)), xs)
  for it in every
    values = [array[x] for (array, f, x) in zip(xs, pred, it[1:end-1]) if f(x)]
    s = unique(values)
    if length(s) > 0
      err = "All inputs to invdupl should be same $s"
      length(s) == 1 || throw(ArgumentError(err))
      answer[it[end]] = s[1]
    end
  end
  answer
end


struct FirstArrow{I} <: PrimArrow end

props(::FirstArrow{I}) where I=
  [[Props(true, Symbol(:x, i), Array{Any}) for i=1:I]...,
   Props(false, :y, Array{Any})]

name(::FirstArrow{I}) where I = :first_arr
FirstArrow(n::Integer) = FirstArrow{n}()
abinterprets(::FirstArrow) = [sizeprop]

"f(x, x) = (x,)"
function first_arr(xs...)
  @assert !any(x->isa(x, AbstractArray), xs)
  first(xs)
end
