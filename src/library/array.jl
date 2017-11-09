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
function sizeprop(::ReshapeArrow, props::IdAbValues)
  # size of the output is value of second input
  # does the second input have the property :value
  if 2 ∈ keys(props) && has(:value)(props[2])
    @show typeof(props[2][:value].value)
    outsz = [props[2][:value].value...]
    IdAbValues(3 => AbValues(:size => Size(outsz)))
  else
    IdAbValues()
  end
end

function Base.reshape(array::Array, newshape::Array)
  reshape(array, (newshape...))
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
    @show sz = abvals[3][:value].value
    IdAbValues(4 => AbValues(:size => Size([sz...])))
  else
    IdAbValues()
  end
end


function scatter_nd(params, indices, shape)
  answer = Array{Float64, length(shape)}(shape...)
  indices = indices + 1
  for (idx,rr) in enumerate(CartesianRange(size(indices)[1:end-1]))
    answer[indices[rr,:]...] = params[idx]
  end
  answer
end
