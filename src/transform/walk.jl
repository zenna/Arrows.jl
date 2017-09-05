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
    replace_sub_arr!(sub_arrow, port_map)
  end

  replarr, port_map = outer(arr)
  rewire!(port_map)
  arr
end

# walk(inner, outer, arr) = walk!(inner, outer, deepcopy(arr))

function rewire(arr, newarr, all_sub_port_map)::CompArrow
  # add the links
  for (src_port, dst_port) in links(arr)
    if src_port ∉ keys(all_sub_port_map)
      println("MISSING", deref(src_port))
    end
    if dst_port ∉ keys(all_sub_port_map)
      println("MISSING", deref(dst_port))
    end
    new_left = all_sub_port_map[src_port]
    new_right = all_sub_port_map[dst_port]
    link_ports!(new_left, new_right)
  end
  newarr
end

"`SubPort` in of replacement `SubArrow` that corresponds to `port`"
replace_port(port::SubPort, arr_to_port_map::Dict{SubPort, SubPort}) =
  arr_to_port_map[sub_arrow(port)][port]

"""Traverses `arr`, applies `inner` to each subarrow then `outer` to parent.
Args
  inner - `orig::SubArrow` -> new::Arrow, portmapize::PortMap` applied to each `SubArrow`,
  outer -
  arr - `CompArrow` to walk
Returns
  res::CompArrow - where `new` in `res` replaces each `orig` in `arr` and
    a `PortMap` where PortMap[p1] = p2 means p1 ∈ orig_arr, p2 ∈ new_arr
  and any edge which connects to p1 in orig will connect to p2 in new.
"""
function walk{I, O}(inner, outer, arr::CompArrow{I, O})
  newarr = CompArrow{I, O}(arr.name, arr.port_props)
  all_sub_port_map = Dict{SubPort, SubPort}()
  for sub_arrow in sub_arrows(arr)
    # FIXME: Non recursive
    replace_arr, port_map = portmapize(inner(sub_arrow)...)
    new_sarr = add_sub_arr!(newarr, replace_arr)
    # println("PORTMAP IS", port_map)
    # println("Port is", port(sub_arrow, 1))
    # Given a sub_arrow I want the
    sub_sub_port_map = Dict()
    for (o, n) in port_map
      a = port(sub_arrow, o)
      b = port(new_sarr, n)
      # println(deref(a), " -> ", deref(b))
      sub_sub_port_map[port(sub_arrow, o)] = port(new_sarr, n)
    end

    for subport in ports(sub_arrow)
      subport ∈ keys(sub_sub_port_map) || println(deref(subport))
    end

    @assert all((subport ∈ keys(sub_sub_port_map) for subport in ports(sub_arrow)))
    merge!(all_sub_port_map, sub_sub_port_map)
  end
  foreach((p1, p2) -> all_sub_port_map[p1] = p2, ports(sub_arrow(arr)),
                                                 ports(sub_arrow(newarr)))
  rewire(arr, newarr, all_sub_port_map)
  #
  # for port in all_sub_ports(newarr)
  #   println(deref(port))
  #   println("LINKS", length(links(arr)), " ", length(all_sub_port_map))
  # end
  @assert all((parent(port) == arr for port in keys(all_sub_port_map)))
  @assert all((parent(port) == newarr for port in values(all_sub_port_map)))
  repl, port_map = portmapize(outer(arr))
end
