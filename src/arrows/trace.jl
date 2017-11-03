"A trace within an arrow uniquely defines a trace `sub_arrow`"
struct TraceSubArrow <: ArrowRef
  arrs::Vector{SubArrow}
end

"TraceSubArrow where `sarr` is the root"
function TraceSubArrow(sarr::SubArrow)
  deref(sarr) isa CompArrow || throw(ArgumentError("Root must be composite"))
  TraceSubArrow([sarr])
end

"TraceSubArrow where subarrow of `carr` is the root"
TraceSubArrow(carr::CompArrow) = TraceSubArrow(sub_arrow(carr))

"`TraceSubArrow` from appending `sarr` to trace `tarr`"
function append(tarr::TraceSubArrow, sarr::SubArrow)
  sarr ∈ sub_arrows(tarr) || throw(ArgumentError("`sarr` not child of `tarr`"))
  TraceSubArrow(vcat(tarr.arrs, sarr))
end

"Which `SubArrow` does `tracearrow` trace to"
sub_arrow(tracearrow::TraceSubArrow)::SubArrow = last(tracearrow.arrs)

"SubArrows of CompArrow that `tarr` refers to"
sub_arrows(tarr::TraceSubArrow) = sub_arrows(deref(tarr))

"Arrow that `trace` references"
deref(trace::TraceSubArrow)::Arrow = deref(last(trace.arrs))

"Port of a `TraceSubArrow`"
struct TraceSubPort <: AbstractPort
  trace_arrow::TraceSubArrow
  port_id::Int
end

"Trace ports of `tarr`"
trace_ports(tarr::TraceSubArrow) =
  [TraceSubPort(tarr, i) for i = 1:length(⬧(deref(tarr)))]

"Which `SubPort` does this `traceport` trace to"
function sub_port(traceport::TraceSubPort)::SubPort
  SubPort(sub_arrow(traceport.trace_arrow), traceport.port_id)
end

"A `Value` of a `TraceSubArrow`"
struct TraceValue <: Value
  parent::TraceArrow    # Composite TraceArrow that Value is within  
  srcvalue::SourceValue
end

src(tprt::TraceSubPort) = TraceArrow( src(sub_port(tprt))

"Trace values of `tarr"
trace_values(tarr::TraceSubArrow) = [TraceValue(tarr, i) for i = 1:length(get_ports(sub_arrow(tarr)))]

"Which `TraceSubPort`s are represented by a `Value`"
function ports(tracevalue::TraceValue)::Vector{TraceSubPort}
  subport = sub_port(tracevalue.srcvalue)
  component = weakly_connected_component(subport)
  [TraceSubPort(tracearrow, subport.id) for subport in component]
end
