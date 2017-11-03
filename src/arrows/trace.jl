"A trace within an arrow uniquely defines a trace `sub_arrow`"
struct TraceArrow <: ArrowRef
  arrs::Vector{SubArrow}
end

TraceArrow(sarr::SubArrow) = TraceArrow([sarr])
TraceArrow(carr::CompArrow) = TraceArrow(sub_arrow(carr))
append(tarr::TraceArrow, sarr::SubArrow) = TraceArrow(vcat(tarr.arrs, sarr))

"Which `SubArrow` does `tracearrow` trace to"
sub_arrow(tracearrow::TraceArrow)::SubArrow = last(tracearrow.arrs)

deref(trace::TraceArrow)::Arrow = deref(last(trace.arrs))

"A port of a `TraceArrow`"
struct TracePort <: AbstractPort
  trace_arrow::TraceArrow
  port_id::Int
end

"Trace ports of `tarr"
trace_ports(tarr::TraceArrow) = [TracePort(tarr, i) for i = 1:length(get_ports(sub_arrow(tarr)))]

"Which `SubPort` does this `traceport` trace to"
function sub_port(traceport::TracePort)::SubPort
  SubPort(sub_arrow(traceport.trace_arrow), traceport.port_id)
end

"A `Value` of a `TraceArrow`"
struct TraceValue <: Value
  srcvalue::TracePort
end

"Trace ports of `tarr"
trace_values(tarr::TraceArrow) = [TraceValue(tarr, i) for i = 1:length(get_ports(sub_arrow(tarr)))]


"Which `TracePort`s are represented by a `Value`"
function ports(tracevalue::TraceValue)::Vector{TracePort}
  subport = sub_port(tracevalue.srcvalue)
  component = weakly_connected_component(subport)
  [TracePort(tracearrow, subport.id) for subport in component]
end
