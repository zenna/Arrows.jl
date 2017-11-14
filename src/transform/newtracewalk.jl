function idportmap(arr1::Arrow, arr2::Arrow, idpmap::PortIdMap)
  # TODO: Some checking here
  idpmap
end

function idportmap(arr1::Arrow, arr2::Arrow, spmap::Dict{Symbol, Symbol})
  @show spmap
  PortIdMap(⬧(arr1, s1).port_id => ⬧(arr2, s2).port_id for (s1, s2) in spmap)
end

"Go down iff CompArrow"
function maybedown(replace::Function,
                   carr::CompArrow,
                   sarr::SubArrow,
                   abtvals::TraceAbValues,
                   tparent::TraceParent)
  newtparent = down(tparent, sarr)
  newtracewalk(replace, carr, abtvals, newtparent)
end

function maybedown(replace::Function,
                   parr::PrimArrow,
                   sarr::SubArrow,
                   abtvals::TraceAbValues,
                   tparent::TraceParent)
  replace(parr, sarr, tparent, abtvals)
end

"""
Traverses `carr`, applies `replace` to each subarrow then `outer` to parent.

# Arguments
- `replace`: `old::SubArrow` -> (new::Arrow, portmap::PortMap)`
           `new` replaces `old` in `carr`
- `carr`:  `CompArrow` to walk over
# Returns
- `res::CompArrow` - where `new` in `res` replaces each `orig` in `arr` and
   a `PortMap` where PortMap[p1] = p2 means p1 ∈ orig_arr, p2 ∈ new_arr
   and any edge which connects to p1 in orig will connect to p2 in new.
"""
function newtracewalk(replace::Function,
                      carr::CompArrow,
                      abtvals::TraceAbValues=traceprop!(carr),
                      tparent::TraceParent=TraceParent(carr))
  newcarr = CompArrow(Symbol(name(carr)))
  for prt in ⬧(carr)
    add_port_like!(newcarr, prt)
  end
  # Map from sarrs in old to replacement
  sarrmap = Dict{SubArrow, SubArrow}(sub_arrow(carr) => sub_arrow(newcarr))
  oldnewpmap = Dict{SubArrow, PortIdMap}(sub_arrow(carr) => id_portid_map(carr))

  # Handle Primitives
  for sarr in sub_arrows(carr)
    replarr, some_port_map = maybedown(replace, deref(sarr), sarr, abtvals, tparent)
    id_port_map = idportmap(deref(sarr), replarr, some_port_map)
    newsarr = add_sub_arr!(newcarr, replarr)
    sarrmap[sarr] = newsarr
    oldnewpmap[sarr] = id_port_map
  end

  # Do the rewiring
  for (l, r) in links(carr)
    portmap = oldnewpmap[l.sub_arrow]
    l.port_id ∉ keys(portmap) && continue
    new_port_id = portmap[l.port_id] # Port id in replacement
    new_sarr = sarrmap[l.sub_arrow]
    l⬨ = sub_port(new_sarr, new_port_id)

    portmap = oldnewpmap[r.sub_arrow]
    r.port_id ∉ keys(portmap) && continue
    new_port_id = portmap[r.port_id] # Port id in replacement
    new_sarr = sarrmap[r.sub_arrow]
    r⬨ = sub_port(new_sarr, new_port_id)
    l⬨ ⥅ r⬨
  end
  replace(newcarr, sub_arrow(newcarr), tparent, abtvals)
end
