"Name (e.g. :value, :size, ...) to abstract value (Singleton, Size, ...)"
AbValues = Dict{Symbol, Any}

"Mapping from `port_id` to abstract values"
IdAbValues = Dict{Int, AbValues}

"Mapping from `TraceValue` name to `AbValues`"
TraceAbValues = Dict{TraceValue, AbValues}

"Mapping from port name to `AbValues`"
NmAbValues = Dict{Symbol, AbValues}

"Mapping from `SubPort` to Abstract Value"
SprtAbValues = Dict{SubPort, AbValues}

"Mapping from `Port` to Abstract Value"
PrtAbValues = Dict{Port, AbValues}

"All kinds of mappings to `AbValues`"
XAbValues = Union{PrtAbValues, SprtAbValues, NmAbValues, TraceAbValues, IdAbValues}

# Conversions
"""Convert `nm::NmAbValues` to `SprtAbValues` where names in `nmabv` are names
of `SubPort`s on `arr`"""
function sprtabv(arr::Arrow, nmabv::NmAbValues)
  pnames = [nm.name for nm in name.(ports(arr))]
  sprtabvs = SprtAbValues()
  for (nm, abv) in nmabv
    if nm in pnames
      sprtabvs[⬨(arr, nm)] = abv
    else
      warn("Passed in name $nm whiich is not a name of any port")
    end
  end
  sprtabvs
end

"Construct NmAbValues by looking up ports of arr in tabv"
function nmfromtabv(tabv::Arrows.TraceAbValues, arr::Arrow)::NmAbValues
  # Assume theres only one tabv that corresponds to 
  tsprts_set = map(Arrows.trace_sub_ports, keys(tabv))
  ids = Int[]
  for sprt in ⬨(arr)
    @show deref(sprt)
    idx = findfirst(tsprts_set) do tsprts
      sprt ∈ map(Arrows.sub_port, tsprts)
    end
    @assert idx != 0
    push!(ids, idx)
  end
  abv = collect(values(tabv))
  @show ids
  Arrows.NmAbValues(port_sym_name(prt) => abv[ids[prt.port_id]] for prt in ⬧(arr))
end

"`TraceAbValue` from `xabv`. Assumes each key in `xabv` corresponds to port on tarr"
function tabvfromxabv(tarr::TraceSubArrow, xabv::XAbValues)::TraceAbValues
  TraceAbValues(TraceValue(trace_port(tarr, x)) => abv for (x, abv) in xabv
                           if x ∈ port_sym_name.(⬧(deref(tarr))))
end

"Return `Port`s on deref(tarr) that are not in `tabv``"
function missingprtsfromtabv(tarr::TraceSubArrow, tabv::TraceAbValues)::Vector{Port}
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
Base.get(tabv::Dict{TraceValue, AbValues}, sprt::SubPort) =
  tabv[trace_value(sprt)]

# Convenience functions for extracting info from XAbValues
has(sm::Symbol) = prop -> haskey(prop, sm)

"Executes a function `true_` if the symbol is present or `else_`"
function if_symbol_on_sport(trcp::TraceAbValues,key::Symbol, sport::SubPort,
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
function allhave(idabv::IdAbValues, abvkey::Symbol, prts::Port...)
  allthere = all((prt.port_id ∈ keys(idabv) for prt in prts))
  allthere && all(has(abvkey), (idabv[pid] for pid in port_id.(prts)))
end

"does `xabv[i][typ]` exist"
function Base.in(xabv::XAbValues, i, typ::Symbol)
  i ∈ keys(xabv) && typ in keys(xabv[i])
end

"All abstract evaluators of `arr`"
all_abinterprets(arr::Arrow)::Set{Function} = Set(vcat(accumapply(abinterprets, arr)...))

"Cycle abstract evaluator of `arr` until a fixed point is reached"
function cycle_abinterprets(arr::PrimArrow, idabv::IdAbValues)
  abinterprets = all_abinterprets(arr)
  atfixedpoint = false
  while !atfixedpoint
    atfixedpoint = true
    for abinterpret in abinterprets
      subabv::IdAbValues = abinterpret(arr, idabv)
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
function tarr_idabv(tarr::TraceSubArrow, abtvals::TraceAbValues)::IdAbValues
  # Get IdAbValues from tarr
  tvals = trace_values(tarr)
  validids = [prt.port_id for prt in ⬧(deref(tarr)) if tvals[prt.port_id] in keys(abtvals)]
  IdAbValues(port_id => abtvals[tvals[port_id]] for port_id in validids)
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
                    tabv::TraceAbValues=TraceAbValues(),
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
    # An abinterpret abstract evaluator is a function which applies f to concrete domains
    parr = deref(tarr)
    @assert isa(parr, PrimArrow)

    # Get IdAbValues from tarr
    tvals = trace_values(tarr)
    validids = [prt.port_id for prt in ⬧(deref(tarr)) if tvals[prt.port_id] in keys(tabv)]
    idabv = IdAbValues(port_id => tabv[tvals[port_id]] for port_id in validids)

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
function traceprop!(carr::CompArrow, sprtprp::SprtAbValues)
  tparent = TraceParent(carr)
  tabv = Dict{TraceValue, AbValues}(TraceValue(tparent, sprt) => props for (sprt, props) in sprtprp)
  traceprop!(carr, tabv)
end

"Does `carr` contain itself?"
isrecursive(carr::CompArrow) = false # FIXME: Implement

"Convenience for specifying abstraact values for subports on root"
function traceprop!(carr::CompArrow, nmabv::NmAbValues)
  @pre !isrecursive(carr)
  tparent = TraceParent(carr)
  sprtabv = SprtAbValues(⬨(carr, nm) => abv for (nm, abv) in nmabv)
  traceprop!(carr, sprtabv)
end
