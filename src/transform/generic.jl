PortMap = Dict{Port, Port}
PortIdMap = Dict{Int, Int}
SubPortMap = Dict{SubPort, SubPort}

"Does `arr` reuse values, i.e. any `Port` project to more than 1 other `Port`"
function no_reuse(arr::CompArrow)::Bool
  all((out_degree(port) == 1 for port in all_src_sub_ports(arr)))
end

"in-place `duplyify`"
function duplify!(arr::CompArrow)
  src_ports = all_src_sub_ports(arr)
  for src_port in src_ports
    # Only need to duplyify ports with multiple recipients
    if out_degree(src_port) > 1 # Replace multiedges with dupls and propagate
      in_ports = out_neighbors(src_port)
      # add a link from port to dupl
      dupl = DuplArrow(length(in_ports))
      dupl = add_sub_arr!(arr, dupl)
      link_ports!(arr, src_port, in_port(dupl, 1))
      # replace each edge src -> p with dupl_i -> p
      for (i, neigh_port) in enumerate(in_ports)
        unlink_ports!(arr, src_port, neigh_port)
        link_ports!(arr, out_port(dupl, i), neigh_port)
      end
    end
  end
  @assert no_reuse(arr)
  arr
end

identity_port_map(arr::RealArrow) = Dict{Int, Int}(i => i for i = 1:num_ports(arr))
portmapize(arr::RealArrow, port_map::PortIdMap) = (arr, port_map)
portmapize(arr::RealArrow) = (arr, identity_port_map(arr))

"Use `Dupl` (i.e. `dupl(x) = (x, x)` to remove ports with more than 1 dest"
duplify(arr::CompArrow) = duplify!(copy(arr))


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
  newarr = CompArrow{I, O}(arr.name, arr.port_attrs)
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

  for port in all_sub_ports(newarr)
    println(deref(port))
    println("LINKS", length(links(arr)), " ", length(all_sub_port_map))
  end
  @assert all((parent(port) == arr for port in keys(all_sub_port_map)))
  @assert all((parent(port) == newarr for port in values(all_sub_port_map)))

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
    link_ports!(newarr, new_left, new_right)
  end

  outer(arr)
end
