"A trace within an arrow uniquely defines a trace `sub_arrow`"
struct TraceSubArrow <: ArrowRef
  sarrs::Vector{SubArrow}
end

"TraceSubArrow where `sarr` is the root"
function TraceSubArrow(sarr::SubArrow)
  deref(sarr) isa CompArrow || throw(ArgumentError("Root must be composite"))
  TraceSubArrow([sarr])
end

isroot(tarr::TraceSubArrow) = length(tarr.sarrs) == 1
haskids(tarr::TraceSubArrow) = length(tarr.sarrs) > 1

"TraceSubArrow with `leaf` of `tarr` removed"
pop(tarr::TraceSubArrow) = TraceSubArrow(tarr.sarrs[1:end-1])
pop!(tarr::TraceSubArrow) = (pop!(tarr.sarrs); tarr)

@pre haskids "Cannot Remove Root" pop, pop!

"TraceSubArrow where subarrow of `carr` is the root"
TraceSubArrow(carr::CompArrow) = TraceSubArrow(sub_arrow(carr))

"`TraceSubArrow` from appending `sarr` to trace `tarr`"
function append(tarr::TraceSubArrow, sarr::SubArrow)
  sarr ∈ sub_arrows(tarr) || throw(ArgumentError("`sarr` not child of `tarr`"))
  TraceSubArrow(vcat(tarr.sarrs, sarr))
end

"Which `SubArrow` does `tracearrow` trace to"
sub_arrow(tarr::TraceSubArrow)::SubArrow = last(tarr.sarrs)

"SubArrows of CompArrow that `tarr` refers to"
sub_arrows(tarr::TraceSubArrow) = sub_arrows(deref(tarr))

"Arrow that `trace` references"
deref(trace::TraceSubArrow)::Arrow = deref(last(trace.sarrs))

"Port of a `TraceSubArrow`"
struct TraceSubPort <: AbstractPort
  trace_arrow::TraceSubArrow
  port_id::Int
end

"`TraceSubPort` referencing `sprt` where trace is `parent`"
function TraceSubPort(parent::TraceSubArrow, sprt::SubPort)
  sub_arrow(sprt) ∈ sub_arrows(parent) || throw(ArgumentError("prt must be in parent"))
  TraceSubPort(append(parent, sub_arrow(sprt)), sprt.port_id)
end

# @pre TraceSubPort

"Trace ports of `tarr`"
trace_ports(tarr::TraceSubArrow) =
  [TraceSubPort(tarr, i) for i = 1:length(⬧(deref(tarr)))]

"Which `SubPort` does this `traceport` trace to"
function sub_port(traceport::TraceSubPort)::SubPort
  SubPort(sub_arrow(traceport.trace_arrow), traceport.port_id)
end

"A `Value` of a `TraceSubArrow`"
struct TraceValue <: Value
  srctprt::TraceSubPort    # Composite TraceArrow that Value is within
  TraceValue(tprt::TracePort) = new(rootsrc(tprt))
end

"""
The root source of a a `TraveValue`.  `src(sprt::SubPort)` is the `SubPort`
that projects to `sprt` within `parent(sprt)`.  In constrast, `rootsrc(tprt)`
projects back through the trace to find the original source.
All `trcsprt` wtihin a `TraceValue` share the same `rootsrc`
"""
function rootsrc(tprt::TracePort)
  srcsprt = src(sub_port(tprt))
  parent = pop(tprt.trace_arrow)
  if on_boundary(srcprt) && !isroot(parent)
    return rootsrc(TraceSubPort(parent, srcsprt.port_id))
  else
    return TraceValue(TraceSubPort(parent, srcsprt))
  end
end

"Two trace values are equal if they share the same `rootsrc`"
isequal(v1::TraceValue, v2::TraceValue)::Bool = isequal(v1.srctprt, v2.srctprt)
hash(tval::TraceValue) = hash(rootsrc(tval))
(==)(v1::TraceValue, v2::TraceValue) = isequal(v1, v2)

"Trace values of `tarr"
trace_values(tarr::TraceSubArrow) = [TraceValue(tarr, i) for i = 1:length(get_ports(sub_arrow(tarr)))]
