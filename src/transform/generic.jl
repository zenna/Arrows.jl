"in-place `duplyify`"
function duplify!(arr::CompArrow)
  src_ports = src_sub_ports(arr)
  for src_port in src_ports
    # Only need to duplyify ports with multiple recipients
    if out_degree(src_port, arr) > 1
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
  @assert all((out_degree(port, arr) == 1 for port in src_sub_ports(arr)))
  arr
end

"Use `Dupl` (i.e. `dupl(x) = (x, x)` to remove ports with more than 1 dest"
duplify(arr::CompArrow) = duplify!(copy(arr))

"""Construct a parametric inverse of comp_arrow
Args:
  comp_arrow: Arrow to invert
  dispatch: Dict mapping comp_arrow class to invert function
Returns:
  A (approximate) parametric inverse of `comp_arrow`"""
function invert(comp_arrow::Arrow, dispatch::Dict{Arrow, Function})::Arrow
  arr_dupld = duplify(comp_arrow)
  port_attr = propagate(arr_dupld)
  inner_invert(arr_dupld, port_attr, dispatch)[0]
end
