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
  sz::Size      # Size of the input to the reduce arrow it inverts
  axis::Int     # Axis reduce arrow inverted on
end
name(::InvReduceSumArrow) = :inv_reduce_sum_arrow
function props(arr::InvReduceSumArrow)
  # need one set of parameters for every element of reduced axis
  nθ = get(arr.sz)[arr.axis] - 1
  θprops = [Props(true, Symbol(:θ, i), Any) for i = 1:nθ]
  foreach(add!(θp), θprops)
  vcat(Props(true, :y, Any), θprops, Props(false, :x, Any))
end

function inv(arr::Arrows.ReduceSumArrow,
             sarr::SubArrow,
             const_in::Vector{Bool},
             tparent::TraceParent,
             abtvals::AbTraceValues)
  # @show root(tparent)
  tarr = TraceSubArrow(tparent, sarr)
  tvals = trace_values(tarr)
  sz = abtvals[tvals[1]][:size]
  @show arr = InvReduceSumArrow(sz, arr.axis)
  warn("CONSTANT HACK")
  arr, Dict(1=>4, 2=>1)
end
