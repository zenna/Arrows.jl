"Mean"
struct MeanArrow{I} <: PrimArrow end
props{I}(::MeanArrow{I}) =
  [[Props(true, Symbol(:x, i), Any) for i=1:I]...,
    Props(false, :y, Any)]

name(::MeanArrow) = :mean
MeanArrow(n::Integer) = MeanArrow{n}()
mean(args...) = sum(args)/length(args)
abinterprets(::MeanArrow) = [sizeprop]

"Reduce Mean"
struct ReduceMean <: PrimArrow end
props(::ReduceMean) = [Props(true, :x, Any), Props(false, :y, Any)]
name(::ReduceMean) = :reduce_mean
abinterprets(::ReduceMean) = [sizeprop]
function sizeprop(::ReduceMean, idabv::IdAbValues)::IdAbValues
  @show idabv
  # @assert false
  IdAbValues(2 => AbValues(:size => Size([])))
end
mean(sprt::SubPort) = ReduceMean()(sprt)


"Variance"
struct VarArrow{I} <: PrimArrow end
name(::VarArrow) = :var
VarArrow(n::Integer) = VarArrow{n}()
props{I}(::VarArrow{I}) =
  [[Props(true, Symbol(:x, i), Any) for i=1:I]...,
    Props(false, :y, Any)]
var(args::Vararg{SubPort}) = var([args...])
var(xs::Vararg{<:Real}) = var(xs)


struct ReduceVarArrow{I} <: PrimArrow end
name(::ReduceVarArrow) = :reduce_var
ReduceVarArrow(n::Integer) = ReduceVarArrow{n}()
props{I}(::ReduceVarArrow{I}) =
  [[Props(true, Symbol(:x, i), Any) for i=1:I]...,
    Props(false, :y, Any)]

# FIXME `reduce_var` and `var` dont handle combinations of ports and numbers
reduce_var(args::Vararg{SubPort}) = var([args...])
reduce_var(xs::Vararg{<:Real}) = var(xs)
function reduce_var(xs::Vararg{<:Array})
  xs = [xs...]
  meanval = mean(xs)
  @show size(meanval)
  dists = [(meanval - x).^2 for x in xs]
  variance = mean(mean(dists))
end

"Reduce and sum"
struct ReduceSumArrow <: PrimArrow
  axis::Int
  keepdims::Bool
end
name(::ReduceSumArrow) = :reduce_sum
props(::ReduceSumArrow) = [Props(true, :x, Any), Props(false, :y, Any)]
reduce_sum(xs::Array, axis) = sum(xs, axis)
abinterprets(::ReduceSumArrow) = [sizeprop]
function sizeprop(arr::ReduceSumArrow, idabv::IdAbValues)::IdAbValues
  # FIXME: Assumes keepdims is true
  if 1 ∈ keys(idabv) && :size in keys(idabv[1])
    sz = idabv[1][:size]
    outsz = deepcopy(sz)
    outsz.dims[arr.axis] = 1
    IdAbValues(2 => AbValues(:size => outsz))
  else
    IdAbValues()
  end
end
#
# struct InvReduceSumArrow <: PrimArrow
#   sz::Size      # Size of the input to the reduce arrow it inverts
#   axis::Int     # Axis reduce arrow inverted on
# end
# name(::InvReduceSumArrow) = :inv_reduce_sum_arrow
# function props(arr::InvReduceSumArrow)
#   # need one set of parameters for every element of reduced axis
#   nθ = get(arr.sz)[arr.axis] - 1
#   θprops = [Props(true, Symbol(:θrs, i), Any) for i = 1:nθ]
#   foreach(add!(θp), θprops)
#   vcat(Props(true, :y, Any), θprops, Props(false, :x, Any))
# end
# abinterprets(::InvReduceSumArrow) = [size]
# function sizeprop(arr::ReduceSumArrow, idabv::IdAbValues)::IdAbValues
#   # FIXME: Assumes keepdims is true
#   if 1 ∈ keys(idabv) && :size in keys(idabv[1])
#     sz = idabv[1][:size]
#     outsz = deepcopy(sz)
#     outsz.dims[arr.axis] = 1
#     IdAbValues(2 => AbValues(:size => outsz))
#   else
#     IdAbValues()
#   end
# end

# function inv(arr::Arrows.ReduceSumArrow, sarr::SubArrow, idabv::IdAbValues)
#   @show idabv
#   InvReduceSumArrow(idabv[1][:size], arr.axis), Dict(:x=>:x, :y=>:y)
# end

"Inverse reduce sum does multiple inverse adds"
function inv(arr::Arrows.ReduceSumArrow, sarr::SubArrow, idabv::IdAbValues)
  sz = idabv[1][:size]
  expanddimsz = get(sz)[arr.axis]   # Size of dimension to invreduce to
  nθ = expanddimsz - 1
  θprops = [Symbol(:θrs, i) for i = 1:nθ]
  carr = CompArrow(:inv_reduce_sum, vcat([:y], θprops), [:x])
  y = ⬨(carr, :y)
  θs = [⬨(carr, θprop) for θprop in θprops]
  foreach(add!(θp), θs)
  tocat = []
  local a
  for θi in θs
    a, b = inv_add()(y, θi)
    push!(tocat, b)
    y = a
  end
  push!(tocat, a)
  @assert length(tocat) == expanddimsz
  # @assert false
  CatArrow(length(tocat), arr.axis)(tocat...) ⥅ ⬨(carr, :x)
  @assert is_wired_ok(carr)
  carr, Dict(:x=>:x, :y=>:y)
end
