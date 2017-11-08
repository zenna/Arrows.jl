"Name (e.g. :value, :size, ...) to abstract value (ConcreteValue, Size, ...)"
AbValues = Dict{Symbol, Any}

"Mapping from `port_id` to abstract values"
IdAbValues = Dict{Int, AbValues}

"Abstract TraceValues assigns abtract values to TraceValues"
AbTraceValues = Dict{TraceValue, AbValues}

# FIXME: This is quite a few layers of misdirection
"Get `sprt` in `val_abval` assuming `sprt` is on root"
Base.get(val_abval::Dict{TraceValue, AbValues}, sprt::SubPort) =
  val_abval[trace_value(sprt)]

has(sm::Symbol) = prop -> haskey(prop, sm)

"All abstract evaluators of `arr`"
all_abinterprets(arr::Arrow)::Set{Function} = Set(vcat(accumapply(abinterprets, arr)...))

"Cycle abstract evaluator of `arr` until a fixed point is reached"
function cycle_abinterprets(arr::PrimArrow, abvals::IdAbValues)
  abinterprets = all_abinterprets(arr)
  atfixedpoint = false
  while !atfixedpoint
    atfixedpoint = true
    for abinterpret in abinterprets
      subabvals::IdAbValues = abinterpret(arr, abvals)
      # Do resolution on each Value
      for i in keys(subabvals)
        if i in keys(abvals)
          resabval = meetall(abvals[i], subabvals[i])
          if resabval != abvals[i]
            abvals[i] = resabval
            atfixedpoint = false
          end
        else
          atfixedpoint = false
          abvals[i] = subabvals[i]
        end
      end
    end
  end
  abvals
end

"""
Propagation
# Arguments
- `carr` - the composite arrow to propagate through
- `val_abval` - any initial values that propagation should be initialized with
- `tparent` - root of trace (this typicaally set automatically)
# Returns
- `val_abval` - mutates and returns val_abval with propagated values
"""
function traceprop!(carr::CompArrow,
                    val_abval::Dict{TraceValue, AbValues}=Dict{TraceValue, AbValues}(),
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
    # An abinterpret abstract evaluator is a function which applies f to concrete domains
    parr = deref(tarr)
    @assert isa(parr, PrimArrow)

    # Get IdAbValues from tarr
    tvals = trace_values(tarr)
    validids = [prt.port_id for prt in ⬧(deref(tarr)) if tvals[prt.port_id] in keys(val_abval)]
    idabvals = IdAbValues(port_id => val_abval[tvals[port_id]] for port_id in validids)

    # Do the actual abstract interpretation
    idabvals = cycle_abinterprets(parr, idabvals)

    # Update `val_abval` with abstract values from idabvals
    # and update times
    for (port_id, idabval) in idabvals
      tval = tvals[port_id]
      if tval ∉ keys(val_abval) || val_abval[tval] != idabval
        val_abval[tval] = idabval
        lastmeet[tval] = t + 1
      end
    end
    t = t + 1
  end
  val_abval
end

"Convenience for specifying abstraact values for subports on root"
function traceprop!(carr::CompArrow,
                    sprtprp::Dict{SubPort, AbValues})
  tparent = TraceParent(carr)
  val_abval = Dict{TraceValue, AbValues}(TraceValue(tparent, sprt) => props for (sprt, props) in sprtprp)
  traceprop!(carr, val_abval)
end

@pre traceprop! !isrecursive(carr)
