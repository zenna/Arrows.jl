PortMap = Dict{Port, Port}

"Does `arr` reuse values, i.e. any `Port` project to more than 1 other `Port`"
function no_reuse(arr::CompArrow)::Bool
  all((out_degree(port, arr) == 1 for port in src_sub_ports(arr)))
end

"in-place `duplyify`"
function duplify!(arr::CompArrow)
  src_ports = src_sub_ports(arr)
  for src_port in src_ports
    # Only need to duplyify ports with multiple recipients
    if out_degree(src_port, arr) > 1 # Replace multiedges with dupls and propagate
      in_ports = out_neighbors(src_port, arr)
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

identity_port_map(arr) = @assert false
portmapize(arr::SubArrow, port_map::PortMap) = (arr, port_map)
portmapize(arr::SubArrow) = (arr, identity_port_map(arr))

"Use `Dupl` (i.e. `dupl(x) = (x, x)` to remove ports with more than 1 dest"
duplify(arr::CompArrow) = duplify!(copy(arr))

"Replace `sarr` with arr"
update_sub_arrow!{I, O}(sarr::SubArrow{I, O}, arr::Arrow{I, O}) =
  arr.parent.sub_arrs[arr.id] = arr

# "Rewire links in `arr`"
# function rewire!(arr::SubArrow, port_map::PortMap)
#   for port in ports(arr)
#     i = port.vertex_id
#     j = port_map[i]
#     if i != j
#       ...
#     end
#   end
#   arr
# end

"`SubPort` in of replacement `SubArrow` that corresponds to `port`"
replace_port(port::SubPort, arr_to_new::Dict{SubPort, SubPort}) =
  arr_to_port_map[sub_arrow(port)][port]

"""Traverses `arr`, applies `inner` to each subarrow then `outer` to parent.

Args
  inner - `orig::SubArrow) -> new::Arrow, portmapize::PortMap` applied to each `SubArrow`,
  outer -
  arr - `CompArrow` to walk
Returns
  res::CompArrow - where `new` in `res` replaces each `orig` in `arr` and
    a `PortMap` where PortMap[p1] = p2 means p1 ∈ orig_arr, p2 ∈ new_arr
  and any edge which connects to p1 in orig will connect to p2 in new.
"""
function walk!(inner, outer, arr::CompArrow)
  for sub_arrow in sub_arrows(arr)
    # FIXME: Non recursive
    replace_arr, port_map = portmapize(f(sub_arrow))
    update_sub_arrow!(arr, replace_arr)
    rewire_ports!(sub_arrow, port_map)
  end
  outer(arr)
end

"Non-mutative `walk!``"
walk(inner, outer, arr::CompArrow) = walk!(inner, outer, copy(arr))
