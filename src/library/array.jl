"Gather"
struct GatherNdArrow <: PrimArrow end
name(::GatherNdArrow)::Symbol = :gather_nd
function props(::GatherNdArrow)
  [Props(true, :x, Any),
   Props(true, :y, Any),
   Props(true, :w, Any),
   Props(false, :z, Any)]
 end

"Reshape"
struct ReshapeArrow <: PrimArrow end
name(::ReshapeArrow)::Symbol = :reshape
props(::ReshapeArrow) = bin_arith_props()
abinterprets(::ReshapeArrow) = [sizeprop]
function sizeprop(::ReshapeArrow, idabv::IdAbValues)
  # size of the output is value of second input
  # does the second input have the property :value
  if 2 ∈ keys(idabv) && has(:value)(idabv[2])
    @show typeof(idabv[2][:value].value)
    outsz = [idabv[2][:value].value...]
    IdAbValues(3 => AbValues(:size => Size(outsz)))
  else
    IdAbValues()
  end
end

"Cat arrows along `axis`"
struct CatArrow{I} <: PrimArrow
  axis::Int
end
name(::CatArrow) = :cat
props(::CatArrow{I}) where I =
  [[Props(true, Symbol(:x, i), Any) for i=1:I]...,
    Props(false, :y, Any)]
CatArrow(n::Integer, axis::Integer) = CatArrow{n}(axis)
function sizeprop(arr::CatArrow, idabv::IdAbValues)
  # @assert false
  IdAbValues()
end
abinterprets(::CatArrow) = [sizeprop]

function Base.reshape(array::Array, newshape::Array)
  reshape(array, (newshape...))
end

"Inverse reshape must take the shape of `value`"
function inv(arr::ReshapeArrow, sarr::SubArrow, abvals::IdAbValues)
  const_in(arr, abvals)[2] || throw(ArgumentError("Nonconst indices unimplemented"))
  # The input shape to the inverse is shape of the input to the forward arr
  sz = abvals[1][:size]
  source = SourceArrow(get(sz))
  carr = CompArrow(:inv_reshape_comp, [:z], [:x])
  z, x = ⬨(carr)
  srcsarr = add_sub_arr!(carr, source)
  rshparr = add_sub_arr!(carr, ReshapeArrow())
  z ⥅ (rshparr, 1)
  (srcsarr, 1) ⥅ (rshparr, 2)
  (rshparr, 1) ⥅ x
  @assert is_wired_ok(carr)
  carr, Dict(3=>1, 1=>2)
end

"GatherND, from TensorFlow"
function gather_nd(params, indices, shape)
  indices = indices + 1
  answer = [params[indices[rr,:]...] for rr in
                        CartesianRange(size(indices)[1:end-1])]
  answer
end
# struct GetIndexArrow <: PrimArrow end
# name(::GetIndexArrow)::Symbol = :getindex
# props(::GetIndexArrow) = bin_arith_props()

# statically compute the shape of the target port
struct ScatterNdArrow <: PrimArrow end
name(::ScatterNdArrow)::Symbol = :scatter_nd
function props(::ScatterNdArrow)
  [Props(true, :x, Any),
   Props(true, :y, Any),
   Props(true, :w, Any),
   Props(false, :z, Any)]
 end

abinterprets(::ScatterNdArrow) = [sizeprop]

mutable struct FakeArray
  count
end
FakeArray() = FakeArray(0)

function getindex(x::FakeArray, index)
  x.count += 1
end

function sizeprop(::ScatterNdArrow, abvals::IdAbValues)
  @show Dict(id => collect(keys(vals)) for (id, vals) in abvals)
  if 3 ∈ keys(abvals) && :value ∈ keys(abvals[3])
    sz = abvals[3][:value].value
    IdAbValues(4 => AbValues(:size => Size([sz...])))
  else
    IdAbValues()
  end
end

function prim_scatter_nd(params, indices, shape, value::T) where {T}
  answer = fill(value, shape)
  indices = indices + 1
  for (idx,rr) in enumerate(CartesianRange(size(indices)[1:end-1]))
    answer[indices[rr,:]...] = params[idx]
  end
  answer
end

function scatter_nd(params, indices, shape)
  prim_scatter_nd(params, indices, shape, 0.0)
end
