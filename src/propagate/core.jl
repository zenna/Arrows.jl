
"Name (e.g. :value, :size, ...) to abstract value (Singleton, Size, ...)"
AbVals = Dict{Symbol, Any}

"Mapping from `port_id` to abstract values"
IdAbVals = Dict{Int, AbVals}

"Mapping from `TraceValue` name to `AbVals`"
TraceAbVals = Dict{TraceValue, AbVals}

"Mapping from port name to `AbVals`"
NmAbVals = Dict{Symbol, AbVals}

"Mapping from `SubPort` to Abstract Value"
SprtAbVals = Dict{SubPort, AbVals}

"Mapping from `Port` to Abstract Value"
PrtAbVals = Dict{Port, AbVals}

"All kinds of mappings to `AbVals`"
XAbVals = Union{PrtAbVals, SprtAbVals, NmAbVals, TraceAbVals, IdAbVals}

# Conversions
"""Convert `nm::NmAbVals` to `SprtAbVals` where names in `nmabv` are names
of `SubPort`s on `arr`"""
function sprtabv(arr::Arrow, nmabv::NmAbVals)
  pnames = [nm.name for nm in name.(ports(arr))]
  sprtabvs = SprtAbVals()
  for (nm, abv) in nmabv
    if nm in pnames
      sprtabvs[⬨(arr, nm)] = abv
    else
      warn("Passed in name $nm whiich is not a name of any port")
    end
  end
  sprtabvs
end

"Construct NmAbVals by looking up ports of arr in tabv"
function nmfromtabv(tabv::TraceAbVals, arr::Arrow)::NmAbVals
  # Assume theres only one tabv that corresponds to 
  tsprts_set = map(trace_sub_ports, keys(tabv))
  ids = Int[]
  for sprt in ⬨(arr)
    idx = findfirst(tsprts_set) do tsprts
      sprt ∈ map(sub_port, tsprts)
    end
    @assert idx != 0
    push!(ids, idx)
  end
  abv = collect(values(tabv))
  @show ids
  NmAbVals(port_sym_name(prt) => abv[ids[prt.port_id]] for prt in ⬧(arr))
end

"`TraceAbValue` from `xabv`. Assumes each key in `xabv` corresponds to port on tarr"
function tabvfromxabv(tarr::TraceSubArrow, xabv::XAbVals)::TraceAbVals
  TraceAbVals(TraceValue(trace_port(tarr, x)) => abv for (x, abv) in xabv
                           if x ∈ port_sym_name.(⬧(deref(tarr))))
end

"Return `Port`s on deref(tarr) that are not in `tabv``"
function missingprtsfromtabv(tarr::TraceSubArrow, tabv::TraceAbVals)::Vector{Port}
  missing = Port[]
  for (i, tval) in enumerate(trace_values(tarr))
    if tval ∉ keys(tabv)
      push!(missing, ⬧(deref(tarr), i))
    end
  end
  missing
end

# FIXME: This is quite a few layers of misdirection
"Get `sprt` in `tabv` assuming `sprt` is on root"
Base.get(tabv::Dict{TraceValue, AbVals}, sprt::SubPort) =
  tabv[trace_value(sprt)]

# Convenience functions for extracting info from XAbVals
has(sm::Symbol) = prop -> haskey(prop, sm)

"Executes a function `true_` if the symbol is present or `else_`"
function if_symbol_on_sport(trcp::TraceAbVals,key::Symbol, sport::SubPort,
                              true_, else_)
  tv = trace_value(sport)
  if tv ∈ keys(trcp)
    inferred = trcp[tv]
    if key ∈ keys(inferred)
      return true_(inferred[key])
    end
  end
  return else_()
end

"All ports in `idabv` have values for "
function allhave(idabv::IdAbVals, abvkey::Symbol, prts::Port...)
  allthere = all((prt.port_id ∈ keys(idabv) for prt in prts))
  allthere && all(has(abvkey), (idabv[pid] for pid in port_id.(prts)))
end

"does `xabv[i][typ]` exist"
function Base.in(xabv::XAbVals, i, typ::Symbol)
  i ∈ keys(xabv) && typ in keys(xabv[i])
end

"All abstract evaluators of `arr`"
all_abinterprets(arr::Arrow)::Set{Function} = Set(vcat(accumapply(abinterprets, arr)...))

"Cycle abstract evaluator of `arr` until a fixed point is reached"
function cycle_abinterprets(arr::PrimArrow, idabv::IdAbVals)
  abinterprets = all_abinterprets(arr)
  atfixedpoint = false
  while !atfixedpoint
    atfixedpoint = true
    for abinterpret in abinterprets
      # @grab arr
      # @grab idabv
      subabv::IdAbVals = abinterpret(arr, idabv)
      # @show subabv
      # Do resolution on each Value
      for i in keys(subabv)
        if i in keys(idabv)
          resabval = meetall(idabv[i], subabv[i])
          if resabval != idabv[i]
            # println("Value refined from $resabval to $idabv")
            idabv[i] = resabval
            atfixedpoint = false
          end
        else
          # println("New data on $(⬧(arr, i)):\n $(subabv[i])")
          atfixedpoint = false
          idabv[i] = subabv[i]
        end
      end
    end
  end
  idabv
end

"Mapping from `port_id` of `tarr` to abstract values within `abtvals`"
function tarr_idabv(tarr::TraceSubArrow, abtvals::TraceAbVals)::IdAbVals
  # Get IdAbVals from tarr
  tvals = trace_values(tarr)
  validids = [prt.port_id for prt in ⬧(deref(tarr)) if tvals[prt.port_id] in keys(abtvals)]
  IdAbVals(port_id => abtvals[tvals[port_id]] for port_id in validids)
end

"""
Propagation
# Arguments
- `carr` - the composite arrow to propagate through
- `tabv` - any initial values that propagation should be initialized with
- `tparent` - root of trace (this typicaally set automatically)
# Returns
- `tabv` - mutates and returns tabv with propagated values
"""
function traceprop!(carr::CompArrow,
                    tabv::TraceAbVals=TraceAbVals(),
                    tparent::TraceParent=TraceParent(carr))
  Time = Int
  tarrs = inner_prim_trace_arrows(carr)
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
  if isempty(tarrs)
    return tabv
  end
  tarrid = 1
  while true
    tarrid = findnext(ready, tarrs, tarrid)
    tarrid = tarrid == 0 ? findfirst(ready, tarrs) : tarrid
    # Converged
    tarrid == 0 && break
    tarr = tarrs[tarrid]
    lastapply[tarr] = t
    # @grab tarr
    # An abinterpret abstract evaluator is a function which applies f to concrete domains
    parr = deref(tarr)
    @assert isa(parr, PrimArrow)

    # Get IdAbVals from tarr
    tvals = trace_values(tarr)
    validids = [prt.port_id for prt in ⬧(deref(tarr)) if tvals[prt.port_id] in keys(tabv)]
    idabv = IdAbVals(port_id => tabv[tvals[port_id]] for port_id in validids)

    # Do the actual abstract interpretation
    idabv = cycle_abinterprets(parr, idabv)

    # Update `tabv` with abstract values from idabv
    # and update times
    for (port_id, idabval) in idabv
      tval = tvals[port_id]
      if tval ∉ keys(tabv) || tabv[tval] != idabval
        tabv[tval] = idabval
        lastmeet[tval] = t + 1
      end
    end
    t = t + 1
  end
  tabv
end

"Convenience for specifying abstraact values for subports on root"
function traceprop!(carr::CompArrow, sprtprp::SprtAbVals)
  tparent = TraceParent(carr)
  tabv = Dict{TraceValue, AbVals}(TraceValue(tparent, sprt) => props for (sprt, props) in sprtprp)
  traceprop!(carr, tabv)
end

"Does `carr` contain itself?"
isrecursive(carr::CompArrow) = false # FIXME: Implement

"Convenience for specifying abstraact values for subports on root"
function traceprop!(carr::CompArrow, nmabv::NmAbVals)
  @pre !isrecursive(carr)
  @pre all([nm in port_sym_names(carr) for nm in keys(nmabv)])
  tparent = TraceParent(carr)
  sprtabv = SprtAbVals(⬨(carr, nm) => abv for (nm, abv) in nmabv)
  traceprop!(carr, sprtabv)
end
