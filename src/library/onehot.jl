# XXX: Lots of redundancy here, can't we do better?

"Converts Int to One Hot Vector of length `bitlength`"
struct IntToOneHot <: PrimArrow
  bitlength::Int # Do we need to encode this?
end
name(::IntToOneHot)::Symbol = :int_to_one_hot
props(::IntToOneHot) = [Props(true, :x, Any), Props(false, :y, Any)]

"Converts One Hot Vector of length `bitlength` to Integer"
struct OneHotToInt <: PrimArrow
  bitlength::Int # Do we need to encode this?
end
name(::OneHotToInt)::Symbol = :one_hot_to_int
props(::OneHotToInt) = [Props(true, :y, Any), Props(false, :x, Any)]

function inv(arr::IntToOneHot, sarr::SubArrow, idabv::IdAbVals)
  OneHotToInt(arr.bitlength), Dict(:x => :x, :y => :y)
end

function sizeprop(arr::IntToOneHot, idabv::IdAbVals)::IdAbVals
  # if input is [a, b, c] then out size is [a, b, c, bitlength]
  # if output is [a, b, c, bitsize] then in size is [a, b, c]
  if in(idabv, 1, :size)
    intsz = get(idabv[1][:size])
    onehotsz = Size([intsz; arr.bitlength])
    # @show intsz, onehotsz, "1 inttoonehot"
    return IdAbVals(2 => AbVals(:size => onehotsz)) 
  elseif in(idabv, 2, :size)
    onehotsz = get(idabv[2][:size])
    intsz = Size(onehotsz[1:end-1])
    # @show intsz, onehotsz, "2 inttoonehot"
    return IdAbVals(1 => AbVals(:size => intsz)) 
  else
    IdAbVals()
  end
end

abinterprets(arr::IntToOneHot) = [sizeprop]

function sizeprop(arr::OneHotToInt, idabv::IdAbVals)::IdAbVals
  if in(idabv, 2, :size)
    @grab intsz = get(idabv[2][:size])
    # @assert false ":aok"
    @grab onehotsz = Size([intsz; arr.bitlength])
    intsz, onehotsz, "2 onehottoint"
    return IdAbVals(1 => AbVals(:size => onehotsz)) 
  elseif in(idabv, 1, :size)
    @grab onehotsz = get(idabv[1][:size])
    # @assert false ":aokadadad"
    intsz = Size(onehotsz[1:end-1])
    # @show intsz, onehotsz, "1 onehottoint"
    return IdAbVals(2 => AbVals(:size => intsz)) 
  else
    IdAbVals()
  end
end

abinterprets(arr::OneHotToInt) = [sizeprop]

function inv(arr::OneHotToInt, sarr::SubArrow, idabv::IdAbVals)
  IntToOneHot(arr.bitlength), Dict(:x => :x, :y => :y)
end 

"Wrap `f` putting one hot <-> int encoders/decoders between inputs and outpts``"
function wraponehot(f::Arrow, bitlength::Int)
  c = CompArrow(pfx(f, :onehot), ▸(f), ◂(f))
  foreach(transferlabels!, ▸(f), ▸(c))
  foreach(transferlabels!, ◂(f), ◂(c))
  fsarr = add_sub_arr!(c, f)
  intxsprts = map(sprt -> OneHotToInt(bitlength)(sprt), ▹(c))
  fsarrin = ▹(fsarr)
  foreach(⥅, intxsprts, ▹(fsarr))
  onehotysprts = map(sprt -> IntToOneHot(bitlength)(sprt), ◃(fsarr))
  foreach(⥅, onehotysprts, ◃(c))
  @post c is_valid(c)
end

"One hot an integer x"
function onehot(x::Integer, bitlength::Integer, T=Float64)
  @pre x < bitlength
  x1hot = zeros(T, bitlength)
  x1hot[x+1] = one(T)
  x1hot
end

"""
```jldoctest
julia> A = rand(1:4, 5)
5-element Array{Int64,1}:
 3
 4
 1
 2
 3

julia> B = onehot(A, 6)
5×6 Array{Float64,2}:
  0.0  0.0  0.0  1.0  0.0  0.0
  0.0  0.0  0.0  0.0  1.0  0.0
  0.0  1.0  0.0  0.0  0.0  0.0
  0.0  0.0  1.0  0.0  0.0  0.0
  0.0  0.0  0.0  1.0  0.0  0.0
```
"""
function onehot(x::Array{<:Integer}, bitlength::Integer, T=Float64)
  x1hot = Array{T}(size(x)..., bitlength)
  for idxs in CartesianRange(size(x))
    x1hot[idxs, :] = onehot(x[idxs], bitlength, T)
  end
  x1hot
  # map(x->onehot(x, bitlength, T), x)
end

"""One hot encoding to integer
julia> invonehot([0,0,0,1])
3
"""
function invonehot(x::Vector{T}) where T
  @pre length(findn(x)) == 1 "x must contain only one `1`, $x"
  pos = findfirst(x) - 1
  @pre pos >= 0
  pos
end

"""
Inverse of one hot for array

```jldoctest
  julia> A = rand(1:4, 5)
5-element Array{Int64,1}:
 1
 2
 2
 4
 3

julia> B = Arrows.onehot(A, 6)
5×6 Array{Float64,2}:
 0.0  1.0  0.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  1.0  0.0
 0.0  0.0  0.0  1.0  0.0  0.0

julia> Arrows.inv

julia> Arrows.invonehot(B)
5-element Array{Int64,1}:
 1
 2
 2
 4
 3
```
"""
function invonehot(x::Array{T, N}) where {T, N}
  @pre N > 1
  y = Array{Int, N-1}(size(x)[1:end-1])
  for idxs in CartesianRange(size(y))
    y[idxs] = invonehot(x[idxs, :])
  end
  y
end