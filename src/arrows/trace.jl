import Base:length

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

"Number of levels in trace"
length(tparent::TraceParent) = length(tparent.sarrs)
@invariant TraceParent all([sarrs[i] ∈ sub_arrows(sarr[i-1]) for i = 2:length(TraceParent)])

"Is `tparent` the root: i.e. parentless"
isroot(tparent::TraceParent) = length(tparent) == 1

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
hash(tparent::TraceParent, h::UInt) = hash((tparent.sarrs, tparent.leaf), h)
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
function TraceSubArrow(sarr::SubArrow)
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

# isroot(tarr::TraceSubArrow) = length(tarr.parent) == 1
# "TraceSubArrow with `leaf` of `tarr` removed"
# function pop(tarr::TraceSubArrow)
#   !isroot(tarr) || throw(ArgumentError("Cannot Remove Root"))
#   TraceSubArrow(tarr.sarrs[1:end-1])
# end
# pop!(tarr::TraceSubArrow) = (pop!(tarr.sarrs); tarr)

# @pre !isroot "Cannot Remove Root" pop, pop!

"TraceSubArrow where subarrow of `carr` is the root"
TraceSubArrow(carr::CompArrow) = TraceSubArrow(sub_arrow(carr))

"`TraceSubArrow` from appending `sarr` to trace `tarr`"
function append(tarr::TraceSubArrow, sarr::SubArrow)
  sarr ∈ sub_arrows(tarr) || throw(ArgumentError("`sarr` not child of `tarr`"))
  TraceSubArrow(vcat(tarr.sarrs, sarr))
end

"Which `SubArrow` does `tracearrow` trace to"
sub_arrow(tarr::TraceSubArrow)::SubArrow = tarr.leaf

# "`SubArrow`s of CompArrow that `tarr` refers to"
# sub_arrows(tarr::TraceSubArrow) = sub_arrows(deref(tarr))
#
# "All `SubArrow`s (inc boundary) of CompArrow that `tarr` refers to"
# all_sub_arrows(tarr::TraceSubArrow) = all_sub_arrows(deref(tarr))

"Arrow that `trace` references"
deref(tarr::TraceSubArrow)::Arrow = deref(tarr.leaf)

"Port of a `TraceSubArrow`"
struct TraceSubPort <: AbstractPort
  trace_arrow::TraceSubArrow
  port_id::Int
end

# "`TraceSubPort` referencing `sprt` where trace is `parent`"
# function TraceSubPort(parent::TraceSubArrow, sprt::SubPort)
#   sub_arrow(sprt) ∈ all_sub_arrows(parent) || throw(ArgumentError("prt must be in parent"))
#   if on_boundary(sprt)
#     TraceSubPort(parent, sprt.port_id)
#   else
#     TraceSubPort(append(parent, sub_arrow(sprt)), sprt.port_id)
#   end
# end

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

# @pre TraceSubPort

"Trace ports of `tarr`"
trace_ports(tarr::TraceSubArrow) =
  [TraceSubPort(tarr, i) for i = 1:length(⬧(deref(tarr)))]

"Which `SubPort` does this `traceport` trace to"
function sub_port(tprt::TraceSubPort)::SubPort
  SubPort(sub_arrow(tprt.trace_arrow), tprt.port_id)
end

"A `Value` of a `TraceSubArrow`"
struct TraceValue <: Value
  srctprt::TraceSubPort    # Composite TraceArrow that Value is within
  TraceValue(tprt::TraceSubPort) = new(rootsrc(tprt))
end
#
# "Parent `TraceArrow`"
# function parenttarr(tprt::TraceSubPort)::TraceSubArrow
#   if on_boundary(sub_port(tprt))
#     tprt.trace_arrow
#   else
#     pop(tprt.trace_arrow)
#   end
# end

"Parent `TraceArrow`"
trace_parent(tprt::TraceSubPort)::TraceParent = trace_parent(tprt.trace_arrow)
trace_parent(tarr::TraceSubArrow)::TraceParent = tarr.parent

"""
The root source of a a `TraveValue`.  `src(sprt::SubPort)` is the `SubPort`
that projects to `sprt` within `parent(sprt)`.  In constrast, `rootsrc(tprt)`
projects back through the trace to find the original source.
All `trcsprt` wtihin a `TraceValue` share the same `rootsrc`
"""
function rootsrc(tprt::TraceSubPort)::TraceSubPort
  println("Got here!!!!!")
  @show srcsprt = src(sub_port(tprt))
  @show tparent = trace_parent(tprt)
  if on_boundary(srcsprt)
    if isroot(tparent)
      println("Found Source on root\n")
      return TraceSubPort(tparent, srcsprt)
    else
      # @assert false #on_boundary(srcsprt)
      # If the source is on boundary and its not a root, need to recurse up
      println("GOING UP!!")
      srctarr = TraceSubArrow(tparent, sub_arrow(srcsprt))
      return rootsrc(TraceSubPort(up(srctarr), srcsprt.port_id))
    end
  elseif deref(sub_arrow(srcsprt)) isa CompArrow
    # If the source is on a CompArrow we need to recursve down
    # @assert false #on_boundary(srcsprt)
    println("GOING DOWN!!")
    srctarr = TraceSubArrow(tparent, sub_arrow(srcsprt))
    return rootsrc(TraceSubPort(down(srctarr), srcsprt.port_id))
  else
    # @assert false #on_boundary(srcsprt)
    @show deref(srcsprt)
    @show deref(sub_arrow(srcsprt))
    @show isroot(tparent)
    @assert deref(sub_arrow(srcsprt)) isa PrimArrow || isroot(tparent)
    println("Found Source on primitive\n")
    return TraceSubPort(tparent, srcsprt)
  end
end

"Two trace values are equal if they share the same `rootsrc`"
isequal(v1::TraceValue, v2::TraceValue)::Bool = isequal(v1.srctprt, v2.srctprt)
hash(tval::TraceValue, h::UInt) = hash(rootsrc(tval), h)
(==)(v1::TraceValue, v2::TraceValue) = isequal(v1, v2)

"Trace values of `tarr"
trace_values(tarr::TraceSubArrow) = [TraceValue(tarr, i) for i = 1:length(get_ports(sub_arrow(tarr)))]

using Base.Test
function test_dept(nlayers = 5)
  carr = TestArrows.nested_core(nlayers)
  sarrs = [sub_arrow(carr)]
  parent = carr
  for i = 1:nlayers + 1
    sarr = sub_arrows(parent)[1]
    push!(sarrs, sarr)
    parent = deref(sarr)
  end
  root = TraceParent(carr)
  tparent = root
  tarrs = []
  for sarr in sarrs[2:end]
    tarr = TraceSubArrow(tparent, sarr)
    tparent = down(tparent, sarr)
    push!(tarrs, tarr)
  end

  xtprts = TraceSubPort[]
  ytprts = TraceSubPort[]
  for tarr in tarrs
    push!(xtprts, TraceSubPort(tarr, 1))
    push!(ytprts, TraceSubPort(tarr, 2))
    # if deref(tarr) isa CompArrow
    #   sarr = sub_arrows(tarr)[1]
    #   xsprt = ⬨(sarr, 1) # 1st fort of only child sarr
    #   push!(xtprts, TraceSubPort(tarr, xsprt))
    #
    #   ysprt = ⬨(sarr, 2) # 1st fort of only child sarr
    #   push!(ytprts, TraceSubPort(tarr, ysprt))
    # end
  end
  xtvals = [TraceValue(xtprt) for xtprt in xtprts]
  @show sub_port(xtvals[1].srctprt)
  @show sub_port(xtvals[2].srctprt)
  @show xtvals[2].srctprt.trace_arrow
  @show xtvals[1].srctprt.trace_arrow
  @show xtvals[1].srctprt.trace_arrow == xtvals[2].srctprt.trace_arrow
  @show xtvals[2].srctprt.port_id == xtvals[1].srctprt.port_id
  @test xtvals[1] == xtvals[2]
  @test same(xtvals)
  ytvals = [TraceValue(ytprt) for ytprt in ytprts]
  println("ALLA!!\n\n")
  for ytval in ytvals
    @show ytval.srctprt.trace_arrow
  end
  @test same(ytvals)
  @test first(xtvals) != first(ytvals)
  @show xtvals[1].srctprt
end

# Printing #
function string(tarr::TraceSubArrow)
  return ""
  sarrsstring = join([string("  [", i, "]: ", sarr) for (i, sarr) in enumerate(tarr.sarrs)], "\n")
  """Trace Arrow
  $(sub_arrow(tarr))

  $sarrsstring
  """
end
show(io::IO, tarr::TraceSubArrow) = print(io, string(tarr))
