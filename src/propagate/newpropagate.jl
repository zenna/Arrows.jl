
"Size of an array"
struct Size
  dims::Array{Nullable{Int64},1}
  rank_unknown::Bool
end

"Propagate shapes"
function shapeprop(::AddArrow, xprops, yprops, zprops)
  @show xprops, yprops, zprops
  @assert false
end

function shapeprop(sarr::SubArrow, args...)
  shapeprop(deref(sarr), args...)
end

"Resolve inconsistencies of values"
function resolve(::Type{Size})
  @assert false
end

ValueProp = Dict{TraceValue, Props}

"Propagate trace value"
function traceprop(carr::CompArrow,
                   prop::Function,
                   resolve::Function,
                   trcarr::TraceArrow = TraceArrow(carr),
                   valprp::ValueProp = ValueProp())
  sarrs = sub_arrows(carr)
  while !isempty(sarrs)
    sarr = pop!(sarrs)
    trcsarr = append(trcarr, sarr)
    trcvals = trace_values(trcsarr)
    vals = [get!(Props, valprp, trcvals) for trcval in trcvals]
    sub_vals = prop(sarr, vals...)
  end
end

function test_tracepop()
  carr = TestArrows.xy_plus_x_arr()
  traceprop(carr, shapeprop, resolve)
end


# WHat to store and what to return
# valprop?

# 