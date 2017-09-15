symb_iden_port_map(arr::Arrow) = Dict{Symbol, Symbol}(zip(port_names(arr)))
iden_port_map(arr::Arrow) = Dict{Int, Int}(i => i for i = 1:num_ports(arr))
portmapize(arr::Arrow, portmap::PortIdMap) = (arr, portmap)
portmapize(arr::Arrow) = (arr, iden_port_map(arr))

sub_port_map(sarr::SubArrow, subportmap::SubPortMap) = subportmap
sub_port_map(sarr::SubArrow, portmap::PortIdMap) =
  SubPortMap(port(sarr, l) => port(sarr, r) for (l, r) in portmap)

"Replace edge `l -> r` in edges with `l -> repl[r]`"
function rewire!(edges::LG.Graph, repl::Associative)
  for edge in LG.edges(edges)
    if edge.src in keys(repl)
      LG.rem_edge!(edge)
      LG.add_edge(edges[edge.src], edge.dst)
    elseif edge.dst in keys(repl)
      LG.rem_edge!(edge)
      LG.add_edge(edge.src, edges[edge.src])
    end
  end
  edges
end

function parent(subportmap::SubPortMap)::CompArrow
  @assert same(parent(subport) for subport in keys(subportmap))
  @assert same(parent(subport) for subport in values(subportmap))
  parent(first(keys(subprtmap)))
end

"For every p1 Rewire the arrow"
function rewire!(port_map::SubPortMap)
  rewire!(parent(port_map),
          SubPortIdMap(port_index(l) => port_index(r) for (l, r) in SubPortMap))
end

"""Traverses `carr`, applies `inner` to each subarrow then `outer` to parent.

# Arguments
  `inner` - `old::SubArrow` -> (new::Arrow, portmap::PortMap)`
             `new` replaces `old` in `carr`
  `outer` - `carr::CompArrow` -> `newcarr::CompArrow`
            `outer` is applied to `carr` after all replacement
  `carr` - `CompArrow` to walk over
# Returns
  `res::CompArrow` - where `new` in `res` replaces each `orig` in `arr` and
    a `PortMap` where PortMap[p1] = p2 means p1 ∈ orig_arr, p2 ∈ new_arr
    and any edge which connects to p1 in orig will connect to p2 in new.
"""
function walk!(inner, outer, carr::CompArrow)::CompArrow
  for sarr in sub_arrows(carr)
    replarr, port_map = portmapize(inner(sarr)...)
    replace_sub_arr!(sarr, replarr, port_map)
  end

  outer(carr)
end

"Non mutating `walk!`"
walk(inner, outer, carr::CompArrow) = walk!(inner, ouer, deepcopy(carr))

"""Traverses `carr`, applies `inner` to each subarrow then `outer` to parent.
"""
function lightwalk(inner, outer, carr::CompArrow)::CompArrow
  foreach(inner, sub_arrows(carr))
  outer(carr)
end
