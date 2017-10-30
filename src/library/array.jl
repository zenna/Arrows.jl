"Gather"
struct GatherNdArrow <: PrimArrow end
name(::GatherNdArrow)::Symbol = :gather_nd
props(::GatherNdArrow) = bin_arith_props()

"Reshape"
struct ReshapeArrow <: PrimArrow end
name(::ReshapeArrow)::Symbol = :reshape
props(::ReshapeArrow) = bin_arith_props()

"GatherND, from TensorFlow"
function gather_nd(params, indices)
  indices = indices + 1
  [params[indices[rr,:]...] for rr in CartesianRange(size(indices)[1:end-1])]
end
# struct GetIndexArrow <: PrimArrow end
# name(::GetIndexArrow)::Symbol = :getindex
# props(::GetIndexArrow) = bin_arith_props()

# statically compute the shape of the target port
struct ScatterNdArrow <: PrimArrow end
name(::ScatterNdArrow)::Symbol = :scatter_nd
props(::ScatterNdArrow) = bin_arith_props()


function scatter_nd(params, indices)
  answer = Array{Any, 3}(1,1024,2)
  indices = indices + 1
  for (idx,rr) in enumerate(CartesianRange(size(indices)[1:end-1]))
    answer[indices[rr,:]...] = params[idx]
  end
  answer
end
