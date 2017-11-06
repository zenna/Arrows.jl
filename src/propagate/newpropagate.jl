PropType = Dict{Symbol, Any}
SubPropType = Dict{Int, PropType}

# FIXME: This is quite a few layers of misdirection
Base.get(valprp::Dict{TraceValue, PropType}, sprt::SubPort) =
         valprp[TraceValue(TraceParent(deref(sprt.sub_arrow)), sprt)]

"Failure to meet different values of type `T`"
struct MeetError{T} <: Exception
  vals::Vector{T}
end

Base.showerror(io::IO, e::MeetError) = print(io, "Could not meet: ", e.vals)

"All abstract evaluators of `arr`"
all_abevals(arr::Arrow)::Set{Function} =
  Set(vcat(accumapply(propagators, arr)...))

"Cycle abstract evaluator of `carr` until a fixed point is reached"
function cycle_abevals(arr::PrimArrow, props::SubPropType)
  abevals = all_abevals(arr)
  atfixedpoint = false
  while !atfixedpoint
    atfixedpoint = true
    for propagator in abevals
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

function traceprop!(carr::CompArrow,
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

function traceprop!(carr::CompArrow,
                     sprtprp::Dict{SubPort, PropType})
  tparent = TraceParent(carr)
  valprp = Dict{TraceValue, PropType}(TraceValue(tparent, sprt) => props for (sprt, props) in sprtprp)
  traceprop!(carr, valprp)
end

@pre traceprop! !isrecursive(carr)

propagators(::Arrow) = [valueprop]
propagators(::ArithArrow) = [sizeprop]
has(sm::Symbol) = prop -> haskey(prop, sm)
