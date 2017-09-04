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
      link_ports!(src_port, in_sub_port(dupl, 1))
      # replace each edge src -> p with dupl_i -> p
      for (i, neigh_port) in enumerate(in_ports)
        unlink_ports!(src_port, neigh_port)
        link_ports!(out_sub_port(dupl, i), neigh_port)
      end
    end
  end
  @assert no_reuse(arr)
  arr
end

"Use `Dupl` (i.e. `dupl(x) = (x, x)` to remove ports with more than 1 dest"
duplify(arr::CompArrow) = duplify!(copy(arr))
