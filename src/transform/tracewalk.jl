
function subtracewalk(inner::Function,
            carr::CompArrow,
            sarr::SubArrow,
            tparent::TraceParent,
            abtvals::AbTraceValues)
  tparent = down(tparent, sarr)
  @show root(tparent)
  inner(sarr, tparent, abtvals)
end

function subtracewalk(inner::Function,
            parr::PrimArrow,
            sarr::SubArrow,
            tparent::TraceParent,
            abtvals::AbTraceValues)
  @show root(tparent)
  inner(sarr, tparent, abtvals)
end

function subtracewalk(inner::Function,
            sarr::SubArrow,
            tparent::TraceParent,
            abtvals::AbTraceValues)
  subtracewalk(inner, deref(sarr), sarr, tparent, abtvals)
end

"""
Traverses `carr`, applies `inner` to each subarrow then `outer` to parent.

# Arguments
- `inner`: `old::SubArrow` -> (new::Arrow, portmap::PortMap)`
           `new` replaces `old` in `carr`
- `outer`: `carr::CompArrow` -> `newcarr::CompArrow`
           `outer` is applied to `carr` after all replacement
- `carr`:  `CompArrow` to walk over
# Returns
- `res::CompArrow` - where `new` in `res` replaces each `orig` in `arr` and
   a `PortMap` where PortMap[p1] = p2 means p1 ∈ orig_arr, p2 ∈ new_arr
   and any edge which connects to p1 in orig will connect to p2 in new.
"""
function tracewalk!(inner::Function,
                    outer::Function,
                    carr::CompArrow,
                    abtvals::AbTraceValues=traceprop!(carr))::CompArrow
  # FIXME: Is this copy necessary?
  println("\nEntering tracewalk")
  tparent = TraceParent(carr)
  @show root(tparent)
  for sarr in sub_arrows(carr)
    replarr, port_map = portmapize(subtracewalk(inner, sarr, tparent, abtvals)...)
    replace_sub_arr!(sarr, replarr, port_map)
  end

  outer(carr)
end
