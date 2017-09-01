PortMap = Dict{Port, Port}
PortIdMap = Dict{Int, Int}
PortSymbMap = Dict{Symbol, Symbol}
SubPortMap = Dict{SubPort, SubPort}

iden_port_map(arr::RealArrow) = Dict{Int, Int}(i => i for i = 1:num_ports(arr))
portmapize(arr::RealArrow, portmap::PortIdMap) = (arr, portmap)
portmapize(arr::RealArrow) = (arr, iden_port_map(arr))

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
    println("HEGHE")
  @show typeof(subportmap)
  @assert same(parent(subport) for subport in keys(subportmap))
  @assert same(parent(subport) for subport in values(subportmap))
  parent(first(keys(subprtmap)))
end

"For every p1 Rewire the arrow"
function rewire!(port_map::SubPortMap)
  rewire!(parent(port_map),
          SubPortIdMap(port_index(l) => port_index(r) for (l, r) in SubPortMap))
end

"""Traverses `arr`, applies `inner` to each subarrow then `outer` to parent.

Args
  inner - `orig::SubArrow` -> new::Arrow, portmapize::PortMap` appl t`SubArrow`,
  outer -
  arr - `CompArrow` to walk
Returns
  res::CompArrow - where `new` in `res` replaces each `orig` in `arr` and
    a `PortMap` where PortMap[p1] = p2 means p1 ∈ orig_arr, p2 ∈ new_arr
  and any edge which connects to p1 in orig will connect to p2 in new.
"""
function walk!{I, O}(inner, outer, arr::CompArrow{I, O})
  for sub_arrow in sub_arrows(arr)
    replarr, port_map = portmapize(inner(sub_arrow)...)
    update_sub_arr!(sub_arrow, replarr)
    println(sub_arrow)
    subportmap = sub_port_map(sub_arrow, port_map)
    rewire!(port_map)
  end

  replarr, port_map = outer(arr)
  rewire!(port_map)
  arr
end

walk(inner, outer, arr) = walk!(inner, outer, deepcopy(arr))
