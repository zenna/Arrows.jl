# TODO
# 1. recurse into CompArrow
# 2. readd sarrs that are propagated to
PropType = Dict{Symbol, Any}
SubPropType = Dict{Int, PropType}


# FIXME: This is quite a few layers of misdirection
ok(valprp::Dict{TraceValue, PropType}, sprt::SubPort) =
  valprp[TraceValue(TraceParent(deref(sprt.sub_arrow)), sprt)]


"Failure to meet different values of type `T`"
struct MeetError{T} <: Exception
  vals::Vector{T}
end

Base.showerror(io::IO, e::MeetError) = print(io, "Could not meet: ", e.vals)

ValueProp = Dict{TraceValue, Props}

"All propagators of `arr`"
allpropagators(arr::Arrow)::Set{Function} = Set(vcat(accumapply(propagators, arr)...))
# allpropagators(arr::CompArrow, valprp::ValProp) =
#   traceprop!(carr, valprp)

"Cycle propagators of `sarr` until a fixed point is reached"
function cyclepropagators!(resolve::Function, sarr::SubArrow, props::SubPropType)
  @show arrprops = allpropagators(deref(sarr))
  atfixedpoint = false
  while !atfixedpoint
    atfixedpoint = true
    for propagator in arrprops
      subprops::SubPropType = propagator(deref(sarr), props)
      # Do resolution on each Value
      for i in keys(subprops)
        if i in keys(props)
          resprop = resolve(props[i], subprops[i])
          if resprop != props[i]
            props[i] = resprop
            atfixedpoint = false
          end
        else
          atfixedpoint = false
          props[i] = subprops[i]
        end
      end
    end
  end
  props
end


# "Propagate properties through `TraceValues`. Mutates valprp"
# function traceprop!(carr::CompArrow,
#                    valprp::Dict{TraceValue, PropType}=Dict{TraceValue, PropType}(),
#                    resolve::Function=meetall,
#                    tparent::TraceParent=TraceParent(carr))
#   sarrs = Set{SubArrow}(sub_arrows(carr))
#   # Propagate until queue exhausted
#   # @show valprp
#   while !isempty(sarrs)
#     sarr = pop!(sarrs)
#     tarr = TraceSubArrow(tparent, sarr)
#     tvals = trace_values(tarr)
#     validids = [prt.port_id for prt in ⬧(sarr) if tvals[prt.port_id] in keys(valprp)]
#     @show validids
#     props = SubPropType(port_id => valprp[tvals[port_id]] for port_id in validids)
#
#     # props = [get!(PropType, valprp, tval) for tval in tvals]
#     props = cyclepropagators!(resolve, sarr, props)
#     seentvals = Set{TraceValue}()
#     for (i, propa) in props
#     # for (i, tval) in enumerate(tvals)
#       tval = tvals[i]
#       if tval ∉ seentvals && (tval ∉ keys(valprp) || props[i] != valprp[tval])
#         valprp[tval] = props[i]
#         for sprt in sub_ports(SrcValue(tval)) # Only update sarrs in this comp
#           if sprt.sub_arrow != sarr && sprt.sub_arrow != sub_arrow(carr)
#             sprt.sub_arrow != sarr && push!(sarrs, sprt.sub_arrow)
#           end
#         end
#       end
#       push!(seentvals, tval)
#     end
#   end
#   valprp
# end
#
#
# function traceprop!(carr::CompArrow,
#                      sprtprp::Dict{SubPort, PropType},
#                      resolve::Function=meetall)
#   tparent = TraceParent(carr)
#   valprp = Dict{TraceValue, PropType}(TraceValue(tparent, sprt) => props for (sprt, props) in sprtprp)
#   traceprop!(carr, valprp, resolve)
# end

"Cycle abstract evaluator of `carr` until a fixed point is reached"
function cycle_abevals(arr::PrimArrow, props::SubPropType)
  @show arrprops = allpropagators(arr)
  atfixedpoint = false
  while !atfixedpoint
    atfixedpoint = true
    for propagator in arrprops
      subprops::SubPropType = propagator(arr, props)
      # Do resolution on each Value
      for i in keys(subprops)
        if i in keys(props)
          resprop = meetall(props[i], subprops[i])
          if resprop != props[i]
            props[i] = resprop
            atfixedpoint = false
          end
        else
          atfixedpoint = false
          props[i] = subprops[i]
        end
      end
    end
  end
  props
end

function traceprop2!(carr::CompArrow,
                     valprp::Dict{TraceValue, PropType}=Dict{TraceValue, PropType}(),
                     tparent::TraceParent=TraceParent(carr))
  Time = Int
  tarrs = inner_trace_arrows(carr)
  # last time a tarr was applied
  lastapply = Dict{TraceSubArrow, Time}(zip(tarrs, fill(-1, length(tarrs))))
  # last time a value was contracted
  lastmeet = Dict{TraceValue, Time}()
  for tarr in tarrs, tval in trace_values(tarr)
    lastmeet[tval] = 0
  end
  t::Time = 0
  # a tarr is ready to to be applied if its values have been `meet`ed more
  # more recently than the last time it was applied
  ready(tarr)::Bool = any(value->lastmeet[value] > lastapply[tarr],
                          trace_values(tarr))
  while true
    println("New iteration")
    tarrid = findfirst(ready, tarrs)
    # Converged
    tarrid == 0 && break
    tarr = tarrs[tarrid]
    lastapply[tarr] = t
    # An abeval abstract evaluator is a function which applies f to concrete domains
    parr = deref(tarr)
    @assert isa(parr, PrimArrow)

    # Get SubPropType from tarr
    tvals = trace_values(tarr)
    validids = [prt.port_id for prt in ⬧(deref(tarr)) if tvals[prt.port_id] in keys(valprp)]
    props = SubPropType(port_id => valprp[tvals[port_id]] for port_id in validids)

    props = cycle_abevals(parr, props)
    for (port_id, prop) in props
      tval = tvals[port_id]
      if tval ∉ keys(valprp) || valprp[tval] != prop
        valprp[tval] = prop
        lastmeet[tval] = t + 1
      end
    end
    t = t + 1
  end
  valprp
end

function traceprop2!(carr::CompArrow,
                     sprtprp::Dict{SubPort, PropType})
  tparent = TraceParent(carr)
  valprp = Dict{TraceValue, PropType}(TraceValue(tparent, sprt) => props for (sprt, props) in sprtprp)
  traceprop2!(carr, valprp)
end

#
# @pre traceprop2! !isrecursive(carr)
#
#
propagators(::Arrow) = [valueprop]
propagators(::ArithArrow) = [sizeprop]
propagators(::SourceArrow) = []
#
has(sm::Symbol) = prop -> haskey(prop, sm)
#
# # extract(SubPropType)
