"All source (projecting) sub_ports"
src_sub_ports(arr::CompArrow)::Vector{SubPort} = filter(is_src, sub_ports(arr))

"All source (projecting) sub_ports"
all_src_sub_ports(arr::CompArrow)::Vector{SubPort} = filter(is_src, all_sub_ports(arr))

"All destination (receiving) sub_ports"
dst_sub_ports(arr::CompArrow)::Vector{SubPorts} = filter(is_dst, sub_ports(arr))

"All source (projecting) sub_ports"
all_dst_sub_ports(arr::CompArrow)::Vector{SubPort} = filter(is_dst, all_sub_ports(arr))

"is `port` a reference?"
is_ref(sport::SubPort) = true

"Is `sport` a port on one of the `SubArrow`s within `arr`"
in(sport::SubPort, arr::CompArrow) = sport ∈ fall_sub_ports(arr)

"Is `link` one of the links in `arr`?"
in(link::Link, arr::CompArrow) = link ∈ links(arr)

"Is `port` within `arr` but not on boundary"
strictly_in(sport::SubPort, arr::CompArrow) = sport ∈ inner_sub_ports(arr)

"Is `arr` a sub_arrow of composition `c_arr`"
in(sarr::SubArrow, carr::CompArrow)::Bool = sarr ∈ all_sub_arrows(carr)

"`PortProp`s of `subport` are `PortProp`s of `Port` it refers to"
port_props(subport::SubPort) = port_props(deref(subport))

"Ensore we find the port"
must_find(i) = i == 0 ? throw(DomainError()) : i

"Get the id of a port from its name"
port_id(port::Arrow, name::Symbol) = must_find(findfirst(port_names(arr), name))

"Get parent of any `x ∈ xs` and check they all have the same parent"
function anyparent(xs::Vararg{<:Union{SubArrow, SubPort}})::CompArrow
  if !same(parent.(xs))
    println("Different parents!")
    throw(DomainError())
  end
  parent(first(xs))
end

"Is this `SubArrow` the parent of itself?"
self_parent(sarr::SubArrow) = parent(sarr) == deref(sarr)

## Graph Modification ##

link_ports!(l, r) =
  link_ports!(promote_left_port(l), promote_right_port(r))
promote_port(port::Port{<:CompArrow}) = SubPort(sub_arrow(port.arrow),
                                                port.port_id)
promote_port(port::SubPort) = port
promote_left_port(port::SubPort) = promote_port(port)
promote_right_port(port::SubPort) = promote_port(port)
promote_left_port(port::Port) = promote_port(port)
promote_right_port(port::Port) = promote_port(port)

# # TODO: Check here and below that Port is valid boundary, i.e. port.arrow = c
# # TODO: DomainError not assert
# @assert parent(r) == c
src_port(src_arr::SubArrow, src_id) =
  self_parent(src_arr) ? in_sub_port(src_arr, src_id) : out_sub_port(src_arr, src_id)

dst_port(dst_arr::SubArrow, dst_id) =
  self_parent(dst_arr) ? out_sub_port(dst_arr, dst_id) : in_sub_port(dst_arr, dst_id)

promote_left_port(pid::Tuple{SubArrow, <:Integer}) = src_port(pid...)
promote_right_port(pid::Tuple{SubArrow, <:Integer}) = dst_port(pid...)
promote_left_port(pid::Tuple{CompArrow, <:Integer}) =
  src_port(sub_arrow(pid[1]), pid[2])
promote_right_port(pid::Tuple{CompArrow, <:Integer}) =
  dst_port(sub_arrow(pid[1]), pid[2])

""
function sub_port_map(from::SubArrow, to::SubArrow, portmap::PortIdMap)::SubPortMap
  SubPortMap(SubPort(from, fromid) => SubPort(to, toid) for (fromid, toid) in portmap)
end

"""Replaces `sarr` in `parent(sarr)` with `arr`
# Arguments:
- `sarr`: `SubArrow` to be replaced
- `arr`: `Arrow` to replace it with
# Returns:
- SubArrow that replaced `sarr`
"""
function replace_sub_arr!(sarr::SubArrow, arr::Arrow, portidmap::PortIdMap)::SubArrow
  if self_parent(sarr)
    println("Cannot replace parent subarrow")
    throw(DomainError())
  end
  parr = parent(sarr)
  replarr = add_sub_arr!(parr, arr)
  subportmap = sub_port_map(sarr, replarr, portidmap)
  for sport in sub_ports(sarr)
    for (l, r) in in_links(sport)
      link_ports!(l, subportmap[r])
    end
    for (l, r) in out_links(sport)
      link_ports!(subportmap[l], r)
    end
  end
  rem_sub_arr!(sarr)
  replarr
end

# Graph traversal
"is vertex `v` a destination, i.e. does it project more than 0 edges"
is_dst(g::LG.DiGraph, v::Integer) = LG.indegree(g, v) > 0

"is vertex `v` a source, i.e. does it receive more than 0 edges"
is_src(g::LG.DiGraph, v::Integer) = LG.outdegree(g, v) > 0

"Is `port` a destination. i.e. does corresponding vertex project more than 0"
is_dst(port::SubPort) = lg_to_p(is_dst, port)

"Is `port` a source,  i.e. does corresponding vertex receive more than 0 edge"
is_src(port::SubPort) = lg_to_p(is_src, port)

"All neighbors of `port`"
neighbors(port::SubPort)::Vector{SubPort} = v_to_p(LG.neighbors, port)

"`Subport`s of ports which `port` receives from"
in_neighbors(port::SubPort)::Vector{SubPort} = v_to_p(LG.in_neighbors, port)

"`Subport`s which `port` projects to"
out_neighbors(port::SubPort)::Vector{SubPort} = v_to_p(LG.out_neighbors, port)

"Return the number of `SubPort`s which begin at `port`"
out_degree(port::SubPort)::Integer = lg_to_p(LG.outdegree, port)

"Number of `SubPort`s which end at `port`"
in_degree(port::SubPort)::Integer = lg_to_p(LG.indegree, port)

"Links that end at `sport`"
in_links(sport::SubPort)::Vector{Link} =
  [Link((neigh, sport)) for neigh in in_neighbors(sport)]

"Links that end at `sport`"
out_links(sport::SubPort)::Vector{Link} =
  [Link((sport, neigh)) for neigh in out_neighbors(sport)]

"`in_links` and `out_links` of `sport`"
all_links(sport::SubPort)::Vector{Link} = vcat(in_links(sport), out_links(sport))

"All neighbouring `SubPort`s of `subarr`, each port connected to each outport"
function out_neighbors(subarr::Arrow)
  ports = Port[]
  for port in out_ports(subarr)
    for neighport in out_neighbors(port)
      push!(ports, neighport)
    end
  end
  ports
end

Component = Vector{SubPort}
Components = Vector{Component}

"""Partition the ports into weakly connected equivalence classes"""
function weakly_connected_components(arr::CompArrow)::Components
  cc = weakly_connected_components(arr.edges)
  pi = i->port_index(arr, i)
  map(component->pi.(component), cc)
end

"Ports in `arr` weakly connected to `port`"
function weakly_connected_component(port::SubPort)::Component
  # TODO: Shouldn't need to compute all connected components just to compute
  arr = parent(port)
  components = weakly_connected_components(arr)
  first((comp for comp in components if port ∈ comp))
end

"`src_port.arrow` such that `src_port -> port`"
src_arrow(port::SubPort)::SubArrow = sub_arrow(src(port))

"`src_port` such that `src_port -> port`"
function src(port::SubPort)::SubPort
  if is_src(port)
    port
  else
    in_neighs = in_neighbors(port)
    @assert length(in_neighs) == 1
    first(in_neighs)
  end
end

## Validation ##

"Should `port` be a src in context `arr`. Possibly false iff is_wired_ok = false"
function should_src(port::SubPort)::Bool
  arr = parent(port)
  if !(port in all_sub_ports(arr))
    errmsg = "Port $port not in ports of $(name(arr))"
    println(errmsg)
    throw(DomainError())
  end
  if strictly_in(port, parent(port))
    is_out_port(port)
  else
    is_in_port(port)
  end
end

"Should `port` be a dst in context `arr`? Maybe false iff is_wired_ok=false"
function should_dst(port::SubPort)::Bool
  arr = parent(port)
  if !(port in all_sub_ports(arr))
    errmsg = "Port $port not in ports of $(name(arr))"
    println(errmsg)
    throw(DomainError())
  end
  if strictly_in(port, parent(port))
    is_in_port(port)
  else
    is_out_port(port)
  end
end

"Is `arr` wired up correctly"
function is_wired_ok(arr::CompArrow)::Bool
  for i = 1:LG.nv(arr.edges)
    if should_dst(sub_port_vtx(arr, i))
      # If it should be a desination
      if !(LG.indegree(arr.edges, i) == 1 &&
           LG.outdegree(arr.edges, i) == 0)
      # TODO: replace error with lens
        errmsg = """vertex $i Port $i should be a dst but
                    indeg is $(LG.indegree(arr.edges, i)) (notbe 1)
                    outdeg is $(LG.outdegree(arr.edges, i) == 0)) (not 0)
                  """
        warn(errmsg)
        return false
      end
    end
    if should_src(sub_port_vtx(arr, i))
      # if it should be a source
      if !(LG.outdegree(arr.edges, i) > 0 || LG.indegree(arr.edges) == 1)
        errmsg = """vertex $i Port $i is source but out degree is
        $(LG.outdegree(arr.edges, i)) (should be >= 1)"""
        warn(errmsg)
        return false
      end
    end
  end
  true
end

## Printing ##
function string(port::SubPort)
  a = "SubArrow $(name(parent(port))) of $(name(parent(port))) - "
  b = string(deref(port))
  string(a, b)
end
print(io::IO, p::SubPort) = print(io, string(p))
show(io::IO, p::SubPort) = print(io, p)

string(pxport::ProxyPort) = "ProxyPort $(pxport.arrname):$(pxport.port_id)"
print(io::IO, p::ProxyPort) = print(io, string(p))
show(io::IO, p::ProxyPort) = print(io, p)
