"Inverse Gather"
function inv_gather()
  c = CompArrow(:inv_gather, [:z, :y, :w, :θgather], [:x,])
  z, y, w, θ = ▸(c)
  x, = ◂(c)
  scatter = add_sub_arr!(c, ScatterNdArrow())
  addprop!(θp, θ)
  z ⥅ (scatter, 1)
  y ⥅ (scatter, 2)
  w ⥅ (scatter, 3)
  θ ⥅ (scatter, 4)
  (scatter, 1) ⥅ x
  c
end

struct InvReduceSumArrow <: PrimArrow
  xs::Size
  axis::Int
end

function inv(arr::Arrows.ReduceSumArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)

  tarr = TraceSubArrow(tparent, sarr)
  @show trace_values(tarr)
  @show tarr
  # @show [tval ∈ keys(abtvals) for tval in ]
  @assert false
  InvReduceSumArrow()
end
