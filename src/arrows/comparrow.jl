import LightGraphs: weakly_connected_components

"""Directed Composite Arrow

A composite arrow is a akin to a function composition, i.e. a program.
"""
type CompArrow{I, O} <: Arrow{I, O}
  name::Symbol         # name of CompArrow
  edges::LG.DiGraph    # Graph over port indices - each port unique id
  port_map::Vector{Port}  # port_map[i] is `Port` with index i in `edges`
  port_attrs::Vector{PortAttrs}    # Mapping from border port to attributes
  sub_arrs::Vector{Union{CompArrow, PrimArrow}}
  sub_arr_vertices::Vector{Vector{Int}}

  function CompArrow{I, O}(name::Symbol,
                           port_attrs::Vector{PortAttrs}) where{I, O}
    if !is_valid(port_attrs, I, O)
      throw(DomainError())
    end
    c = new()
    nports = I + O
    g = LG.DiGraph(nports)
    port_map = [Port(c, i) for i=1:nports]
    c.name = name
    c.port_map = port_map
    c.edges = g
    c.port_attrs = port_attrs
    c.sub_arrs = [c]
    c.sub_arr_vertices = [Vector{Int}(1:nports)]
    c
  end
end

"Not a reference"
RealArrow = Union{CompArrow, PrimArrow}

"Constructs CompArrow with where all input and output types are `Any`"
function CompArrow{I, O}(name::Symbol) where {I, O}
  # Default is for first I ports to be in_ports then next O oout_ports
  in_port_attrs = [PortAttrs(true, Symbol(:inp_, i), Any) for i = 1:I]
  out_port_attrs = [PortAttrs(false, Symbol(:out_, i), Any) for i = 1:O]
  port_attrs = vcat(in_port_attrs, out_port_attrs)
  CompArrow{I, O}(name, port_attrs)
end

"Port Attributes of *boundary* ports of arrow"
port_attrs(arr::CompArrow) = arr.port_attrs

"Name of a composite arrow"
name(arr::CompArrow) = arr.name

"A referece to a `Port`"
struct PortRef{T <: Integer} <: AbstractPort
  arrow::CompArrow
  vertex_id::T
end

"Find the vertex index of this port in `arr edges"
port_index(arr::CompArrow, port::PortRef)::Integer = port.vertex_id

port_attrs(portref::PortRef) = port_attrs(deref(portref))

"`PortRef` with vertex index `i` in arr.edges"
function port_index(arr::CompArrow, i::Integer)::PortRef
  nsubports = num_all_sub_ports(arr)
  if 1 <= i <= nsubports
    PortRef(arr, i)
  else
    throw(DomainError())
  end
end

"`id`th sub_arrow in (some kind of) ordering of sub_arrows of `arr`"
struct SubArrowRef{I, O} <: ArrowRef{I, O}
  parent::CompArrow
  id::Int
end

"Dereference `arr` into `RealArrow`"
function deref(arr::SubArrowRef)
  newarr = arr.parent.sub_arrs[arr.id]
  @assert !is_ref(newarr)
  newarr
end

"Dereference `port`"
function deref(port::PortRef)::Port
  @assert is_ref(port)
  port.arrow.port_map[port.vertex_id]
end

"ith sub arrow (reference) of `arr`"
function sub_arrow(arr::CompArrow, i::Integer)::SubArrowRef
  subarr = arr.sub_arrs[i]
  SubArrowRef{num_in_ports(subarr), num_out_ports(subarr)}(arr, i)
end

"Return all the sub_arrows of `arr` excluding arr itself"
sub_arrows(arr::CompArrow)::Vector{SubArrowRef} = all_sub_arrows(arr)[2:end]

"Return all the sub_arrows of `arr` including arr itself"
all_sub_arrows(arr::CompArrow)::Vector{SubArrowRef} =
  [sub_arrow(i) for i = 1:num_all_sub_arrows]

"Number of sub_ports (inclusuive of boundary)"
num_all_sub_ports(arr::CompArrow) = length(arr.port_map)

"Number of sub_ports (exclusive of boundary)"
num_sub_ports{I, O}(arr::CompArrow{I, O}) = num_all_sub_ports(arr) - (I + O)

"All ports w/in `arr`: `⋃([ports(sa) for sa in all_sub_arrows(arr)])`"
all_sub_ports(arr::CompArrow)::Vector{PortRef} =
  [PortRef(arr, i) for i = 1:num_all_sub_ports(arr)]

"All source (projecting) sub_ports"
src_sub_ports(arr::CompArrow)::Vector{PortRef} =
  filter(port->is_src(port, arr), sub_ports(arr))

"All destination (receiving) sub_ports"
dst_sub_ports(arr::CompArrow) = filter(port->is_dst(port, arr), sub_ports(arr))

"is `port` a reference?"
is_ref(port::PortRef) = true

"Add a port inside the composite arrow"
function add_port!(arr::CompArrow, port)::Port
  push!(arr.port_map, port)
  LG.add_vertex!(arr.edges)
  port
end

"Is `port` within `arr`"
function in(port::PortRef, arr::CompArrow)::Bool
  if port.arrow == arr
    nsubports = num_all_sub_ports(arr)
    1 <= port.vertex_id <= nsubports
  end
  false
end

"Is `port` within `arr`"
function strictly_in{I, O}(port::PortRef, arr::CompArrow{I, O})::Bool
  if port.arrow == arr
    nsubports = num_sub_ports(arr)
    return I + O < port.vertex_id <= I + O + nsubports
  end
  false
end

"Is `arr` a sub_arrow of composition `c_arr`"
in(arr::SubArrowRef, c_arr::CompArrow)::Bool = arr in all_sub_arrows(p)

"Number of sub_arrows in `c_arr` including `c_arr`"
num_all_sub_arrows(arr::CompArrow) = length(arr.sub_arrs)

"Number of sub_arrows"
num_sub_arrows(arr::CompArrow) = num_all_sub_arrows(arr) - 1

"All ports(references) of a sub_arrow(reference)"
ports(sarr::SubArrowRef)::Vector{PortRef} =
  [PortRef(sarr.parent, v_id) for v_id in sarr.parent.sub_arr_vertices[sarr.id]]

"Add a sub_arrow `arr` to composition `c_arr`"
function add_sub_arr!{I, O}(c_arr::CompArrow, arr::Arrow{I, O})::Arrow
  last_index = num_all_sub_arrows(c_arr)
  next_index = last_index + 1
  v_id_start = c_arr.sub_arr_vertices[last_index][end] + 1
  push!(c_arr.sub_arr_vertices, Vector{Int}(v_id_start:v_id_start+I+O-1))
  push!(c_arr.sub_arrs, arr)
  sarr = sub_arrow(c_arr, next_index)
  for port in ports(arr)
    add_port!(c_arr, port)
  end
  sarr
end

"Add an edge in CompArrow from port `l` to port `r`"
function link_ports!(c::CompArrow, l::PortRef, r::PortRef)
  l_idx = port_index(c, l)
  r_idx = port_index(c, r)
  LG.add_edge!(c.edges, l_idx, r_idx)
end

"Add an edge in CompArrow from port `l` to port `r`"
function link_ports!(c::CompArrow, l::Port, r::PortRef)
  @assert l.arrow == c
  link_ports!(c, PortRef(c, l.index), r)
end

"Add an edge in CompArrow from port `l` to port `r`"
function link_ports!(c::CompArrow, l::PortRef, r::Port)
  @assert l.arrow == c
  link_ports!(c, l, PortRef(c, r.index))
end

# """ Add edge in `c` `src_id`th projecting port of `src_arr` to
# `dest_id`receiving port of `dest_arr`"""
# function link_ports!(c::CompArrow, src_arr::Arrow, src_id::Integer,
#                      dest_arr::Arrow, dest_id::Integer)
#   src_port = src_arr == c ? in_port(src_arr, src_id) : out_port(src_arr, src_id)
#   dest_port = dest_arr == c ? out_port(dest_arr, dest_id) : in_port(dest_arr, dest_id)
#   link_ports!(c, src_port, dest_port)
# end

"Remove an edge in CompArrow from port `l` to port `r`"
function unlink_ports!(c::CompArrow, l::PortRef, r::PortRef)
  l_idx = port_index(c, l)
  r_idx = port_index(c, r)
  rem_edge!(c.edges, l_idx, r_idx)
end

# Graph traversal
"is vertex `v` a destination, i.e. does it project more than 0 edges"
is_dst(g::LG.DiGraph, v::Integer) = LG.indegree(g, v) > 0

"is vertex `v` a source, i.e. does it receive more than 0 edges"
is_src(g::LG.DiGraph, v::Integer) = LG.outdegree(g, v) > 0

#FIXME: Turn this into a macro for type stability
"""
Helper function to translate LightGraph functions to Port functions
  f: LightGraph API function f(g::Graph, v::VertexId)
  port: port corresponding to vertex to which f(v) is applied
  arr: Parent Composite arrow
"""
function lg_to_p(f::Function, port::PortRef, arr::CompArrow)
  f(arr.edges, port_index(arr, port))
end

"Helper for LightGraph API methods which return Vector{Port}, see `lg_to_p`"
function v_to_p(f::Function, port::PortRef, arr::Arrow)
  map(i->port_index(arr, i), lg_to_p(f, port, arr))
end

"Is port a destination. i.e. does corresponding vertex project more than 0"
is_dst(port::PortRef, arr::CompArrow) = lg_to_p(is_dst, port, arr)

"Is port a source,  i.e. does corresponding vertex receive more than 0"
is_src(port::PortRef, arr::CompArrow) = lg_to_p(is_src, port, arr)

"Vector of all neighbors of `port`"
neighbors(port::PortRef, arr::CompArrow)::Vector{PortRef} = v_to_p(LG.neighbors, port, arr)

"Vector of ports which `port` receives from"
in_neighbors(port::PortRef, arr::CompArrow)::Vector{PortRef} = v_to_p(LG.in_neighbors, port, arr)

"Vector of ports which `port` projects to"
out_neighbors(port::PortRef, arr::CompArrow)::Vector{PortRef} = v_to_p(LG.out_neighbors, port, arr)

"Return the number of ports which begin at port p"
out_degree(port::PortRef, arr::CompArrow)::Integer = lg_to_p(LG.outdegree, port, arr)

"Return the number of ports which end at port p"
in_degree(port::PortRef, arr::CompArrow)::Integer = lg_to_p(LG.indegree, port, arr)

"All neighbouring ports of `subarr`, each port connected to each outport"
function out_neighbors(subarr::Arrow, arr::CompArrow)
  ports = Port[]
  for port in out_ports(subarr)
    for neighport in out_neighbors(port, arr)
      push!(ports, neighport)
    end
  end
  ports
end

# FIXME: This can be done much more quickly with connected components on LG
"Set of ports which are directly or indirectly connected to `port` within `arr`"
function connected(port::PortRef, arr::CompArrow)::Set{PortRef}
  seen = Set{Port}()
  to_see = Set{Port}(port)
  equiv = Set{Port}()
  # import pdb; pdb.set_trace()
  while length(to_see) > 0
    port = pop!(to_see)
    push!(seen, port)
    for neigh in neighbors(port, arr)
      add!(equiv, neigh)
      if neigh ∉ seen
          add!(to_see, neigh)
        end
      end
    end
  return equiv
end

Components = Vector{Vector{Port}}

"""Partition the ports into weakly connected equivalence classes"""
function weakly_connected_components(arr::CompArrow)::Components
  cc = weakly_connected_components(arr.edges)
  pi = i->port_index(arr, i)
  map(component->pi.(component), cc)
end

"Ports in `arr` weakly connected to `port`"
function weakly_connected_component(arr::CompArrow, port::Port)::Vector{Port}
  # TODO: Shouldn't need to compute all connected components just to compute
  # connected component of `port`
  weakly_connected_component(arr, port, weakly_connected_components(port.arrow))
end

# For efficiently (to avoid recomputing `components`)
function weakly_connected_component(arr::CompArrow, port::Port,
                          components::Components)::Vector{Port}
  first((comp for comp in components if port ∈ comp))
end

# Edge trarversal
"`src_port.arrow` such that `src_port -> port`"
function src_arrow(arr::CompArrow, port::Port)::Arrow
  src(arr, port).arrow
end

"`src_port` such that `src_port -> port`"
function src(arr::CompArrow, port::Port)::Port
  if is_src(port, arr)
    port
  else
    in_neighs = in_neighbors(arr, port)
    @assert length(in_neighs) == 1
    first(in_neighs)
  end
end

# Sanity

"Should `port` be a src in context `arr`. Possibly false iff is_wired_ok = false"
function should_src(port::PortRef, arr::CompArrow)::Bool
  if !(port in all_sub_ports(arr))
    errmsg = "Port $port not in ports of $(name(arr))"
    println(errmsg)
    throw(DomainError())
  end
  if strictly_in(port, port.arrow)
    is_out_port(port)
  else
    is_in_port(port)
  end
end

"Should `port` be a dest in context `arr`? Maybe false iff is_wired_ok=false"
function should_dst(port::PortRef, arr::CompArrow)::Bool
  if !(port in all_sub_ports(arr))
    errmsg = "Port $port not in ports of $(name(arr))"
    println(errmsg)
    throw(DomainError())
  end
  if strictly_in(port, port.arrow)
    is_in_port(port)
  else
    is_out_port(port)
  end
end

"Is `arr` wired up correctly"
function is_wired_ok(arr::CompArrow)::Bool
  for i = 1:LG.nv(arr.edges)
    if should_dst(port_index(arr, i), arr)
      # If it should be a desination
      if !(LG.indegree(arr.edges, i) == 1 &&
           LG.outdegree(arr.edges, i) == 0)
      # TODO: replace error with lens
        errmsg = """vertex $i Port $(port_index(arr, i)) should be a dest but
                    indeg is $(LG.indegree(arr.edges, i)) (notbe 1)
                    outdeg is $(LG.outdegree(arr.edges, i) == 0)) (not 0)
                  """
        warn(errmsg)
        return false
      end
    end
    if should_src(port_index(arr, i), arr)
      # if it should be a source
      if !(LG.outdegree(arr.edges, i) > 0 || LG.indegree(arr.edges) == 1)
        errmsg = """vertex $i Port $(port_index(arr, i)) is source but out degree is
        $(LG.outdegree(arr.edges, i)) (should be >= 1)"""
        warn(errmsg)
        return false
      end
    end
  end
  true
end
