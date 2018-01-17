"All source (projecting) sub_ports"
src_sub_ports(arr::CompArrow)::Vector{SubPort} = ⬨(arr, is_src)

"All source (projecting) sub_ports"
all_src_sub_ports(arr::CompArrow)::Vector{SubPort} = filter(is_src, all_sub_ports(arr))

"All destination (receiving) sub_ports"
dst_sub_ports(arr::CompArrow)::Vector{SubPort} = ⬨(arr, is_dst)

"All source (projecting) sub_ports"
all_dst_sub_ports(arr::CompArrow)::Vector{SubPort} = filter(is_dst, all_sub_ports(arr))

"Is `sport` a port on one of the `SubArrow`s within `arr`"
function in(sport::SubPort, carr::CompArrow)::Bool
  sarr = sub_arrow(sport)
  (sarr ∈ carr) &&  (0 < sport.port_id <= num_ports(sarr))
end

"Is `link` one of the links in `arr`?"
in(link::Link, arr::CompArrow) = link ∈ links(arr)

"Is a name of a `SubArrow`"
in(name::ArrowName, arr::CompArrow)::Bool =
  haskey(arr.sarr_name_to_arrow, name)

"Is `sport` a boundary `SubPort` (i.e. not `SubPort` of inner `SubArrow`)"
is_boundary(sprt::SubPort) = sprt ∈ ⬨(sub_arrow(sprt))

"Is `port` within `arr` but not on boundary"
function strictly_in(sprt::SubPort, arr::CompArrow)
  (sprt ∈ arr) && !on_boundary(sprt)
end

"Is `arr` a sub_arrow of composition `c_arr`"
function in(sarr::SubArrow, carr::CompArrow)::Bool
  (parent(sarr) == carr) && (name(sarr) ∈ carr)
end
# Port Properties
"`PortProp`s of `subport` are `PortProp`s of `Port` it refers to"
props(subport::SubPort) = props(deref(subport))

"Ensore we find the port"
must_find(i) = i == 0 ? throw(DomainError()) : i

"Get parent of any `x ∈ xs` and check they all have the same parent"
function anyparent(xs::Vararg{<:Union{SubArrow, SubPort}})::CompArrow
  if !same(parent.(xs))
    throw(ArgumentError("Different parents!"))
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
  self_parent(src_arr) ? ▹(src_arr, src_id) : ◃(src_arr, src_id)

dst_port(dst_arr::SubArrow, dst_id) =
  self_parent(dst_arr) ? ◃(dst_arr, dst_id) : ▹(dst_arr, dst_id)

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
    throw(ArgumentError("Cannot replace parent subarrow"))
  end
  parr = parent(sarr)
  replarr = add_sub_arr!(parr, arr)
  subportmap = sub_port_map(sarr, replarr, portidmap)
  for (l, r) in subportmap
    if is_dst(l)
      for (a, b) in in_links(l)
        link_ports!(a, r)
      end
    elseif is_src(l)
      for (a, b) in out_links(l)
        link_ports!(r, b)
      end
    end
  end
  #
  #   link_ports!(l, r)
  # end
  # for sport in ⬨(sarr)
  #   for (l, r) in in_links(sport)
  #     link_ports!(l, subportmap[r])
  #   end
  #   for (l, r) in out_links(sport)
  #     link_ports!(subportmap[l], r)
  #   end
  # end
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
neighbors(port::SubPort)::Vector{SubPort} = v_to_p(LG.all_neighbors, port)

"`Subport`s of ports which `port` receives from"
in_neighbors(port::SubPort)::Vector{SubPort} = v_to_p(LG.in_neighbors, port)

"`Subport`s which `port` projects to"
out_neighbors(port::SubPort)::Vector{SubPort} = v_to_p(LG.out_neighbors, port)

"Return the number of `SubPort`s which begin at `port`"
out_degree(port::SubPort)::Integer = lg_to_p(LG.outdegree, port)

"Number of `SubPort`s which end at `port`"
in_degree(port::SubPort)::Integer = lg_to_p(LG.indegree, port)

"Number of `SubPort`s which end at `port`"
degree(port::SubPort)::Integer = lg_to_p(LG.degree, port)

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

"out_neighbors"
function out_neighbors(sprts::Vector{SubPort})::Vector{SubPort}
  neighs = SubPort[]
  for sprt in sprts
    for dst_sprt in out_neighbors(sprt)
      push!(neighs, dst_sprt)
    end
  end
  neighs
end

Component = Vector{SubPort}
Components = Vector{Component}

"""Partition the ports into weakly connected equivalence classes"""
function weakly_connected_components(arr::CompArrow)::Components
  cc = LG.weakly_connected_components(arr.edges)
  pi = i->sub_port_vtx(arr, i)
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
src_sub_arrow(port::SubPort)::SubArrow = sub_arrow(src(port))

"`src_port` such that `src_port -> port`"
function src(sprt::SubPort)::SubPort
  if is_src(sprt)
    sprt
  elseif is_dst(sprt)
    in_neighs = in_neighbors(sprt)
    length(in_neighs) == 1 || throw(ArgumentError("#in_neighs of $(sprt) should be 1 but is $(length(in_neighs))"))
    first(in_neighs)
  elseif should_src(sprt)
    sprt
  else
    throw(ArgumentError("No `src` $sprt should be dst but has no in_link "))
  end
end

# FIXME: Overly restrictive Fix dst like we fixed `src`
"`dst_sprt` such that `sprt -> dst_psrt` and `dst_sprt` is unique"
function dst(sprt::SubPort)::SubPort
  if is_dst(sprt)
    sprt
  else
    out_neighs = out_neighbors(sprt)
    length(out_neighs) == 1 || throw(ArgumentError("dst not unique"))
    first(out_neighs)
  end
end

## Validation ##

"Should `port` be a src in context `arr`. Possibly false iff is_valid = false"
function should_src(sport::SubPort)::Bool
  arr = parent(sport)
  if sport ∉ arr
    throw(ArgumentError("Port $port not in ports of $(name(arr))"))
  end
  if strictly_in(sport, parent(sport))
    is_out_port(sport)
  else
    is_in_port(sport)
  end
end

"Should `port` be a dst in context `arr`? Maybe false iff is_valid=false"
function should_dst(sport::SubPort)::Bool
  arr = parent(sport)
  if sport ∉ arr
    throw(ArgumentError("Port $port not in ports of $(name(arr))"))
  end
  if strictly_in(sport, parent(sport))
    is_in_port(sport)
  else
    is_out_port(sport)
  end
end

"Is `arr` wired up correctly"
function is_wired_ok(arr::CompArrow)::Bool
  seen = Set{Int}()
  for (pxport, vtxid) in arr.port_to_vtx_id
    sarr = SubPort(arr, pxport)
    push!(seen, vtxid)
    if should_dst(sarr)
      # If it should be a desination
      if !(LG.indegree(arr.edges, vtxid) == 1 &&
           LG.outdegree(arr.edges, vtxid) == 0)
      # TODO: replace error with lens
        errmsg = """vertex $vtxid Port $(sarr) should be a dst but
                    indeg is $(LG.indegree(arr.edges, vtxid)) (should be 1)
                    outdeg is $(LG.outdegree(arr.edges, vtxid)) (should be 0)
                  """
        warn(errmsg)
        return false
      end
    end
    if should_src(sarr)
      # if it should be a source
      if !(LG.outdegree(arr.edges, vtxid) > 0 || LG.indegree(arr.edges) == 1)
        errmsg = """vertex $vtxid Port $(sarr) is source but out degree is
        $(LG.outdegree(arr.edges, vtxid)) (should be >= 1)"""
        warn(errmsg)
        return false
      end
    end
  end
  n = LG.nv(arr.edges)
  if (length(seen) != n) || ((n > 0) && (max(seen...) != n))
    errmsg = """The number of subports is $(length(seen)) but should
    be $(n) or some port has a bigger vertex id $(max(seen...))"""
    warn(errmsg)
    return false
  end
  true
end

"Is `carr` and all `CompArrow`s it contained wired_ok?"
is_wired_ok_recur(carr::CompArrow) = all(maprecur(is_wired_ok, carr))

"Is `carr` well formed"
function is_valid(carr::CompArrow)
  is_wired_ok_recur(carr) && !hasduplicates(name.(ports(carr)))
end

## Linking to Parent ##
"Is `sprt` loose (not connected)?"
loose(sprt::SubPort)::Bool = degree(sprt) == 0

"Create a new port in `parent(sprt)` like `sprt` and link `sprt` to it"
function link_to_parent!(sprt::SubPort)::Port
  if on_boundary(sprt)
    throw(ArgumentError("invalid on boundary ports"))
  end
  arr = parent(sprt)
  newport = add_port_like!(arr, deref(sprt))
  if is_out_port(sprt)
    link_ports!(sprt, newport)
  else
    link_ports!(newport, sprt)
  end
  newport
end

# FIXME: Deprecate in favour of sub_arrow filter
"Link all `sprt::SubPort ∈ sprts` to parent if preds(sprt)"
link_to_parent!(sprts::Vector{SubPort}, pred) =
  foreach(link_to_parent!, filter(pred, sprts))

# FIXME: Deprecate in favour of sub_arrow filter
"Link all `sprt::SubPort ∈ sarr` to parent if preds(sprt)"
link_to_parent!(sarr::SubArrow, pred) =
  link_to_parent!(⬨(sarr), pred)

# FIXME: Deprecate this in favour of convenient syntax for filter vector ports
"Link `sprt::SubPort ∈ sarr` to parent if `pred(sprt)``"
link_to_parent!(carr::CompArrow, pred)::CompArrow =
  (foreach(sarr -> link_to_parent!(sarr, pred), sub_arrows(carr)); carr)

## Convenience

"Is any subarrow of `carr` of type ArrowType?"
hasarrtype(carr::CompArrow, ArrowType::Type) =
  any(arr->arr isa ArrowType, Arrows.simplewalk(deref, carr))


# FIXME: Deprecate
n▸ = num_in_ports
n◂ = num_out_ports

## Printing ##
function describe(carr::CompArrow; kwargs...)
  """$(func_decl(carr; kwargs...))
  $(num_sub_arrows(carr)) sub arrows
  wired_ok? $(is_valid(carr))"""
end

string(carr::CompArrow) = describe(carr)
print(io::IO, carr::CompArrow) = print(io, string(carr))
show(io::IO, carr::CompArrow) = print(io, carr)

string(sarr::SubArrow) = """$(name(sarr)) ∈ $(deref(sarr))"""

function string(port::SubPort)
  a = "SubPort $(name(port)) "
  b = string(deref(port))
  string(a, b)
end
print(io::IO, p::SubPort) = print(io, string(p))
show(io::IO, p::SubPort) = print(io, p)

string(pxport::ProxyPort) = "ProxyPort $(pxport.arrname):$(pxport.port_id)"
print(io::IO, p::ProxyPort) = print(io, string(p))
show(io::IO, p::ProxyPort) = print(io, p)
