# TODO
# 1. recurse into CompArrow
# 2. readd sarrs that are propagated to

"Resolve inconsistencies of values"
function resolve(new_props, old_props)
  @assert false
end

ValueProp = Dict{TraceValue, Props}

"Propagate trace value"
function traceprop(carr::CompArrow,
                   prop::Function,
                   resolve::Function,
                   trcarr::TraceSubArrow = TraceSubArrow(carr),
                   valprp::ValueProp = ValueProp())
  sarrs = sub_arrows(carr)
  while !isempty(sarrs)
    sarr = pop!(sarrs)
    trcsarr = append(trcarr, sarr)
    trcvals = trace_values(trcsarr) # TODO: traec_Values doesn't work
    vals = [get!(Props, valprp, trcvals) for trcval in trcvals]
    # TODO: integrate vals into valprp
    sub_vals = prop(sarr, vals...)
    foreach(sub_vals, vals) do
      valprp[val] = resolve(old_val, new_val)
      # TODO add those value which changed to sarrs if not already there
    end
  end
  valprp
end


function prop(carr::CompArrow, args...)
  traceprop(carr, prop, resolve, trcarr)
end

function shapeprop(sarr::SubArrow, args...)
  shapeprop(deref(sarr), args...)
end


## Shape
## -----


"Size of an array"
struct Size
  dims::Array{Nullable{Int64},1}
  rank_unknown::Bool
end

"Propagate shapes"
function sizeprop(::AddArrow, xprops, yprops, zprops)
  xprops, yprops, zprops
  # check if any hvae shapes, if so, propagate to the rest
  #
  @assert false
end

# "Propagate shapes"
# function sizeprop(::Arrows.ReshapeArrow, xprops, yprops, zprops)
#   xprops, yprops, zprops
#   # check if any hvae shapes, if so, propagate to the rest
#   #
#   @assert false
# end

function test_tracepop()
  carr = TestArrows.xy_plus_x_arr()
  traceprop(carr, shapeprop, resolve)
end
