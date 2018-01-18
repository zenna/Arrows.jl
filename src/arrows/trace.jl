"""
Parent of Trace. `sarrs[1]` is `root` of the trace.
sarrs[i] ∈ sub_arrows(sarr[i-1]) for i = 2:n
"""
struct TraceParent
  sarrs::Vector{SubArrow}
end

"`TraceParent` where `sarr` is the root"
function TraceParent(sarr::SubArrow)
  deref(sarr) isa CompArrow || throw(ArgumentError("Root must be CompArrow"))
  TraceParent([sarr])
end

"`TraceParent` where `carr` is the root"
function TraceParent(carr::CompArrow)
  TraceParent([sub_arrow(carr)])
end

@invariant TraceParent all([sarrs[i] ∈ sub_arrows(sarr[i-1]) for i = 2:length(TraceParent)])

"Root `sarr`"
root(tparent::TraceParent) = tparent.sarrs[1]

"Is `tparent` the root: i.e. parentless"
isroot(tparent::TraceParent) = length(tparent.sarrs) == 1 #length(tparent) == 1

"Get lower most context"
bottom(tparent::TraceParent)::SubArrow = tparent.sarrs[end]

"One step up the trace"
function up(tparent::TraceParent)
  !isroot(tparent) || throw(ArgumentError("Cannot go up on root"))
  TraceParent(tparent.sarrs[1:end-1])
end

"Down one step in the trace through `sarr`"
function down(tparent::TraceParent, sarr::SubArrow)
  sarr ∈ sub_arrows(deref(bottom(tparent))) || throw(ArgumentError("sarr must be subarrow of bottom(tparent)"))
  TraceParent(vcat(tparent.sarrs, sarr))
end

isequal(tparent1::TraceParent, tparent2::TraceParent)::Bool =
  isequal(tparent1.sarrs, tparent2.sarrs)
hash(tparent::TraceParent, h::UInt) = hash(tparent.sarrs, h)
(==)(tparent1::TraceParent, tparent2::TraceParent) = isequal(tparent1, tparent2)

"A trace within an arrow uniquely defines a trace `sub_arrow`"
struct TraceSubArrow <: ArrowRef
  parent::TraceParent # Parent sarrs
  leaf::SubArrow
end

isequal(tarr1::TraceSubArrow, tarr2::TraceSubArrow)::Bool =
  isequal(tarr1.parent, tarr2.parent) && isequal(tarr1.leaf, tarr2.leaf)
hash(tarr::TraceSubArrow, h::UInt) = hash((tarr.parent, tarr.leaf), h)
(==)(tarr1::TraceSubArrow, tarr2::TraceSubArrow) = isequal(tarr1, tarr2)

"`TraceSubArrow` where `sarr` is the root"
function TraceSubArrow(sarr::SubArrow)::TraceSubArrow
  deref(sarr) isa CompArrow || throw(ArgumentError("Root must be CompArrow"))
  TraceSubArrow(TraceParent([sarr]), sarr)
end

"Go up the trace"
function up(tarr::TraceSubArrow)
  deref(tarr) isa CompArrow || throw(ArgumentError("Can go up only on CompArrows"))
  TraceSubArrow(up(tarr.parent), bottom(tarr.parent))
end

"Down one step in stack trace and let carr become new leaf"
function down(tarr::TraceSubArrow)
  deref(tarr) isa CompArrow || throw(ArgumentError("Can go down only on CompArrows"))
  TraceSubArrow(down(tarr.parent, tarr.leaf), sub_arrow(deref(tarr)))
end

"TraceSubArrow where subarrow of `carr` is the root"
TraceSubArrow(carr::CompArrow) = TraceSubArrow(sub_arrow(carr))

"Which `SubArrow` does `tracearrow` trace to"
sub_arrow(tarr::TraceSubArrow)::SubArrow = tarr.leaf

"Arrow that `trace` references"
deref(tarr::TraceSubArrow)::Arrow = deref(tarr.leaf)

"Get all trace arrows within `carr`"
function inner_trace_arrows(carr::CompArrow, tparent::TraceParent = TraceParent(carr))
  @pre !isrecursive(carr)
  tarrs::Vector{TraceSubArrow} = TraceSubArrow[]
  sarrs = sub_arrows(carr)
  csarrs, ptarrs = partition(sarr -> isa(deref(sarr), CompArrow), sarrs)
  tarrs = vcat(tarrs, [TraceSubArrow(tparent, ptarr) for ptarr in ptarrs])
  for csarr in csarrs
    tarrs = vcat(tarrs, inner_trace_arrows(deref(csarr), down(tparent, csarr)))
  end
  tarrs
end

"Port of a `TraceSubArrow`"
struct TraceSubPort <: AbstractPort
  trace_arrow::TraceSubArrow
  port_id::Int
end

"`TraceSubPort` referencing `sprt` where trace is `parent`"
function TraceSubPort(tparent::TraceParent, sprt::SubPort)
  sub_arrow(sprt) ∈ all_sub_arrows(deref(bottom(tparent))) || throw(ArgumentError("prt must be in parent"))
  tarr = TraceSubArrow(tparent, sub_arrow(sprt))
  TraceSubPort(tarr, sprt.port_id)
end

isequal(tprt1::TraceSubPort, tprt2::TraceSubPort)::Bool =
  isequal(tprt1.trace_arrow, tprt2.trace_arrow) && isequal(tprt1.port_id, tprt2.port_id)
hash(tprt::TraceSubPort, h::UInt) = hash((tprt.trace_arrow, tprt.port_id), h)
(==)(tprt1::TraceSubPort, tprt2::TraceSubPort) = isequal(tprt1, tprt2)

"Trace ports of `tarr`"
trace_ports(tarr::TraceSubArrow) =
  [TraceSubPort(tarr, i) for i = 1:length(⬧(deref(tarr)))]

in_trace_ports(tarr::TraceSubArrow) =
  [TraceSubPort(tarr, prt.port_id) for prt in ▸(deref(tarr))]

out_trace_ports(tarr::TraceSubArrow) =
  [TraceSubPort(tarr, prt.port_id) for prt in ◂(deref(tarr))]


"Which `SubPort` does this `traceport` trace to"
function sub_port(tprt::TraceSubPort)::SubPort
  SubPort(sub_arrow(tprt.trace_arrow), tprt.port_id)
end


"""
The root source of a a `TraceValue`.  `src(sprt::SubPort)` is the `SubPort`
that projects to `sprt` within `parent(sprt)`.  In constrast, `rootsrc(tprt)`
projects back through the trace to find the original source.
All `trcsprt` wtihin a `TraceValue` share the same `rootsrc`
"""
function rootsrc(tprt::TraceSubPort)::TraceSubPort
  srcsprt = src(sub_port(tprt))
  tparent = trace_parent(tprt)
  if on_boundary(srcsprt)
    if isroot(tparent)
      return TraceSubPort(tparent, srcsprt)
    else
      # If the source is on boundary and its not a root, need to recurse up
      srctarr = TraceSubArrow(tparent, sub_arrow(srcsprt))
      return rootsrc(TraceSubPort(up(srctarr), srcsprt.port_id))
    end
  elseif deref(sub_arrow(srcsprt)) isa CompArrow
    # If the source is on a CompArrow we need to recursve down
    srctarr = TraceSubArrow(tparent, sub_arrow(srcsprt))
    return rootsrc(TraceSubPort(down(srctarr), srcsprt.port_id))
  else
    # @assert false #on_boundary(srcsprt)
    @assert deref(sub_arrow(srcsprt)) isa PrimArrow || isroot(tparent)
    return TraceSubPort(tparent, srcsprt)
  end
end


"A `Value` of a `TraceSubArrow`"
struct TraceValue <: Value
  srctprt::TraceSubPort    # Composite TraceArrow that Value is within
  TraceValue(tprt::TraceSubPort) = new(rootsrc(tprt))
end


"Parent `TraceArrow`"
trace_parent(tprt::TraceSubPort)::TraceParent = trace_parent(tprt.trace_arrow)
trace_parent(tarr::TraceSubArrow)::TraceParent = tarr.parent

"Two trace values are equal if they share the same `rootsrc`"
isequal(v1::TraceValue, v2::TraceValue)::Bool = isequal(v1.srctprt, v2.srctprt)
hash(tval::TraceValue, h::UInt) = hash(tval.srctprt, h)
(==)(v1::TraceValue, v2::TraceValue) = isequal(v1, v2)

"`TraceSubPort` referencing `sprt` where trace is `parent`"
TraceValue(tparent::TraceParent, sprt::SubPort) =
  TraceValue(TraceSubPort(tparent, sprt))

"Trace ports of `tarr`"
trace_values(tarr::TraceSubArrow) = map(TraceValue, trace_ports(tarr))

in_trace_values(tarr::TraceSubArrow) = map(TraceValue, in_trace_ports(tarr))

out_trace_values(tarr::TraceSubArrow) = map(TraceValue, out_trace_ports(tarr))

"All the trace values inside `carr`"
inner_trace_values(carr::CompArrow)::Vector{TraceValue} =
  unique(vcat(trace_values.(inner_trace_arrows(carr))...))

# FIXME: Maybe rename this, a sprt could be in many trace values, so name
# should reflect its teh root
"`TraceValue` where parent `sprt` is root `TraceParent`"
trace_value(sprt::SubPort) = TraceValue(TraceParent(deref(sprt.sub_arrow)), sprt)

"Recursively find destinations"
function recurdst(dstsprt::SubPort, tparent::TraceParent)::Vector{TraceSubPort}
  if on_boundary(dstsprt)
    if isroot(tparent)
      return TraceSubPort[TraceSubPort(tparent, dstsprt)]
    else
      # If the source is on boundary and its not a root, need to recurse up
      srctarr = TraceSubArrow(tparent, sub_arrow(dstsprt))
      return out_neighbors(TraceSubPort(up(srctarr), dstsprt.port_id))
    end
  elseif deref(sub_arrow(dstsprt)) isa CompArrow
    # If the source is on a CompArrow we need to recursve down
    srctarr = TraceSubArrow(tparent, sub_arrow(dstsprt))
    return out_neighbors(TraceSubPort(down(srctarr), dstsprt.port_id))
  else
    # @assert false #on_boundary(dstsprt)
    @assert deref(sub_arrow(dstsprt)) isa PrimArrow || isroot(tparent)
    return TraceSubPort[TraceSubPort(tparent, dstsprt)]
  end
end

"All `TraceSubPort`s that `tprt` projects to"
function out_neighbors(tprt::TraceSubPort)::Vector{TraceSubPort}
  tparent = trace_parent(tprt)
  dstsprts = out_neighbors(sub_port(tprt))
  tsprts = TraceSubPort[]
  for dstsprt in dstsprts
    append!(tsprts, recurdst(dstsprt, tparent))
  end
  tsprts
end

"`TraceSubPort`s within `TraceValue`"
trace_sub_ports(tval::TraceValue)::Vector{TraceSubPort} =
  vcat([tval.srctprt], out_neighbors(tval.srctprt))

function trace_sub_arrows(tval::TraceValue)::Vector{TraceSubArrow}
  unique(map(tsprt -> tsprt.trace_arrow, trace_sub_ports(tval)))
end

"SubPorts ∈ Value"
function SrcValue(tval::TraceValue)::SrcValue
  SrcValue(sub_port(tval.srctprt))
end

# Printing #
function string(tparent::TraceParent)
  join([string("  [", i, "]: ", sarr) for (i, sarr) in enumerate(tparent.sarrs)], "\n")
end

show(io::IO, tparent::TraceParent) = print(io, string(tparent))

function string(tarr::TraceSubArrow)
  sarrsstring = join([string("  [", i, "]: ", sarr) for (i, sarr) in enumerate(tarr.parent.sarrs)], "\n")
  """Trace Arrow
  $(sub_arrow(tarr))

  $sarrsstring
  """
end

show(io::IO, tarr::TraceSubArrow) = print(io, string(tarr))
show(io::IO, tval::TraceValue) = print(io, string(tval))

function string(tval::TraceValue)
  """TraceValue
  $(tval.srctprt)
  """
end
#
# "Depth First Trace Iterator"
# struct DFTraceIter
#   tarr::TraceSubArrow
#   pos::Vector{Int}
# end
#
# trace_sub_arrows(carr::CompArrow) = DFTraceIter(TraceSubArrow(carr))
# Base.eltype(::Type{DFTraceIter}) = TraceSubArrow
# function Base.start(it::DFTraceIter)
#   [1]
# end
#
# function Base.next(it::DFTraceIter, state)
#   pos, tarr = state.pos, state.tarr
#   sarr = sub_arrows(it.tarr)[state]
#   # If current state is composite arrow go down
#   if deref(tarr) isa CompArrow
#     downtarr = down(tarr)
#     (downtarr, DFTraceIter(downtarr, push(pos, 1)))
#   elseif pos + 1 > length(sarrs)
#     next(DFTraceIter(down(it.tarr), pop(pos)))
#   else
#     sarr = sarrs[pos + 1]
#   end
#     DFTraceIter(down(it.tarr), push(pos, 1))
#   elseif atend
#     = (it.f(), nothing)
#     if root
#       finish
#     else
#       up
#     end
#   else
#     ...
#   end
# end
#
# ## The state required for this iteration is
# ## the number in the set of sub arrows
#
# function Base.done(it::DFTraceIter, state)
#   if atroot(it, state) && state == length(all_sub_arrows(it.tarr))
#     true
#   else
#     false
#   end
# end
#
# Base.iteratorsize(::Type{<:DFTraceIter}) = Base.IsInfinite()
# Base.iteratoreltype(::Type{<:DFTraceIter}) = Base.HasEltype()
