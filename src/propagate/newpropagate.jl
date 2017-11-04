# TODO
# 1. recurse into CompArrow
# 2. readd sarrs that are propagated to

"Failure to unify different values of type `T`"
struct UnificationError{T} <: Exception
  vals::Vector{T}
end

Base.showerror(io::IO, e::UnificationError) = print(io, "Could not unify: ", e.vals)

"Resolve inconsistencies of values"
function resolve(new_props, old_props)
  @assert false
end

ValueProp = Dict{TraceValue, Props}

"Propagate trace value"
function traceprop(carr::CompArrow,
                   prop::Function,
                   resolve::Function,
                   tparent::TraceParent=TraceParent(carr),
                   valprp::Dict{<:Value, Props})
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

"Unify many values of type `T`"
function unify{T}(::Type{T}, vals::T...)
  mostprecise = first(vals)
  if length(vals) == 1
    return mostprecise
  else
    for val in vals[2:end]
      mostprecise = unify(T, mostprecise, val)
    end
    return mostprecise
  end
end

# "Propagate shapes"
# function sizeprop(::Arrows.ReshapeArrow, xprops, yprops, zprops)
#   xprops, yprops, zprops
#   # check if any hvae shapes, if so, propagate to the rest
#   #
#   @assert false
# end

using Base.Test

function unifybytype
end

function test_prop()
  carr = TestArrows.xy_plus_x_arr()
  x,y,z = ⬧(carr)
  initprops = Dict(x=>Size([nothing, 10]), y=>Size([10, nothing]))
  vals = traceprop(carr, shapeprop, unifybytype)
  @test vals[z].shape = Size(10, 10)
end
