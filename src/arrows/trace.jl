"A trace within an arrow uniquely defines a trace `sub_arrow`"
struct TraceSubArrow <: ArrowRef
  sarrs::Vector{SubArrow}
end

isequal(tarr1::TraceSubArrow, tarr2::TraceSubArrow)::Bool =
  isequal(tarr1.sarrs, tarr2.sarrs)
hash(tarr::TraceSubArrow, h::UInt) = hash(tarr.sarrs, h)
(==)(tarr1::TraceSubArrow, tarr2::TraceSubArrow) = isequal(tarr1, tarr2)

"TraceSubArrow where `sarr` is the root"
function TraceSubArrow(sarr::SubArrow)
  deref(sarr) isa CompArrow || throw(ArgumentError("Root must be composite"))
  TraceSubArrow([sarr])
end

isroot(tarr::TraceSubArrow) = length(tarr.sarrs) == 1
haskids(tarr::TraceSubArrow) = length(tarr.sarrs) > 1

"TraceSubArrow with `leaf` of `tarr` removed"
function pop(tarr::TraceSubArrow)
  !isroot(tarr) || throw(ArgumentError("Cannot Remove Root"))
  TraceSubArrow(tarr.sarrs[1:end-1])
end
pop!(tarr::TraceSubArrow) = (pop!(tarr.sarrs); tarr)

# @pre !isroot "Cannot Remove Root" pop, pop!

"TraceSubArrow where subarrow of `carr` is the root"
TraceSubArrow(carr::CompArrow) = TraceSubArrow(sub_arrow(carr))

"`TraceSubArrow` from appending `sarr` to trace `tarr`"
function append(tarr::TraceSubArrow, sarr::SubArrow)
  sarr ∈ sub_arrows(tarr) || throw(ArgumentError("`sarr` not child of `tarr`"))
  TraceSubArrow(vcat(tarr.sarrs, sarr))
end

"Which `SubArrow` does `tracearrow` trace to"
sub_arrow(tarr::TraceSubArrow)::SubArrow = last(tarr.sarrs)

"`SubArrow`s of CompArrow that `tarr` refers to"
sub_arrows(tarr::TraceSubArrow) = sub_arrows(deref(tarr))

"All `SubArrow`s (inc boundary) of CompArrow that `tarr` refers to"
all_sub_arrows(tarr::TraceSubArrow) = all_sub_arrows(deref(tarr))

"Arrow that `trace` references"
deref(trace::TraceSubArrow)::Arrow = deref(last(trace.sarrs))

"Port of a `TraceSubArrow`"
struct TraceSubPort <: AbstractPort
  trace_arrow::TraceSubArrow
  port_id::Int
end

"`TraceSubPort` referencing `sprt` where trace is `parent`"
function TraceSubPort(parent::TraceSubArrow, sprt::SubPort)
  sub_arrow(sprt) ∈ all_sub_arrows(parent) || throw(ArgumentError("prt must be in parent"))
  if on_boundary(sprt)
    TraceSubPort(parent, sprt.port_id)
  else
    TraceSubPort(append(parent, sub_arrow(sprt)), sprt.port_id)
  end
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
  @show tprt.port_id
  @show tprt.trace_arrow.sarrs
  SubPort(sub_arrow(tprt.trace_arrow), tprt.port_id)
end

"A `Value` of a `TraceSubArrow`"
struct TraceValue <: Value
  srctprt::TraceSubPort    # Composite TraceArrow that Value is within
  TraceValue(tprt::TraceSubPort) = new(rootsrc(tprt))
end

"Parent `TraceArrow`"
function parenttarr(tprt::TraceSubPort)::TraceSubArrow
  if on_boundary(sub_port(tprt))
    tprt.trace_arrow
  else
    pop(tprt.trace_arrow)
  end
end

"""
The root source of a a `TraveValue`.  `src(sprt::SubPort)` is the `SubPort`
that projects to `sprt` within `parent(sprt)`.  In constrast, `rootsrc(tprt)`
projects back through the trace to find the original source.
All `trcsprt` wtihin a `TraceValue` share the same `rootsrc`
"""
function rootsrc(tprt::TraceSubPort)::TraceSubPort
  println("Got here!!!!!")
  srcsprt = src(sub_port(tprt))
  parent = parenttarr(tprt)
  if on_boundary(srcsprt)
    if isroot(parent)
      println("Found Source on root\n")
      return TraceSubPort(parent, srcsprt)
    else
      # @assert false #on_boundary(srcsprt)
      # If the source is on boundary and its not a root, need to recurse up
      println("GOING UP!!")
      return rootsrc(TraceSubPort(parent, srcsprt.port_id))
    end
  elseif deref(sub_arrow(srcsprt)) isa CompArrow
    # If the source is on a CompArrow we need to recursve down
    # @assert false #on_boundary(srcsprt)
    println("GOING DOWN!!")
    rootsrc(TraceSubPort(append(parent, sub_arrow(srcsprt)), srcsprt.port_id))
  else
    # @assert false #on_boundary(srcsprt)
    @assert deref(srcsprt) isa PrimArrow || isroot(parent)
    println("Found Source on primitive\n")
    return TraceSubPort(parent, srcsprt)
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
  root = TraceSubArrow(carr)
  tarrs = [root]
  for sarr in sarrs[2:end]
    tarr = append(root, sarr)
    root = tarr
    tarr
    push!(tarrs, tarr)
  end

  xtprts = TraceSubPort[]
  ytprts = TraceSubPort[]
  for tarr in tarrs
    push!(xtprts, TraceSubPort(tarr, 1))
    push!(ytprts, TraceSubPort(tarr, 2))
    if deref(tarr) isa CompArrow
      sarr = sub_arrows(tarr)[1]
      xsprt = ⬨(sarr, 1) # 1st fort of only child sarr
      push!(xtprts, TraceSubPort(tarr, xsprt))

      ysprt = ⬨(sarr, 2) # 1st fort of only child sarr
      push!(ytprts, TraceSubPort(tarr, ysprt))
    end
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
end

# Printing #
function string(tarr::TraceSubArrow)
  sarrsstring = join([string("  [", i, "]: ", sarr) for (i, sarr) in enumerate(tarr.sarrs)], "\n")
  """Trace Arrow
  $(sub_arrow(tarr))

  $sarrsstring
  """
end
show(io::IO, tarr::TraceSubArrow) = print(io, string(tarr))
