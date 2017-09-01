import LightGraphs: weakly_connected_components

"""Composite Arrow

A composite arrow is a akin to a function composition, i.e. a program.
"""
type CompArrow{I, O} <: Arrow{I, O}
  name::Symbol         # name of CompArrow
  edges::LG.DiGraph    # Graph over port indices - each port unique id
  port_map::Vector{Port}  # port_map[i] is `Port` with index i in `edges`
  port_props::Vector{PortProps}    # Mapping from border port to attributes
  sub_arrs::Vector{Union{CompArrow, PrimArrow}}
  sub_arr_vertices::Vector{Vector{Int}}

  # Invariants
  # length(sub_arrs) == length(sub_arr_vertices)

  function CompArrow{I, O}(name::Symbol,
                           port_props::Vector{PortProps}) where{I, O}
    if !is_valid(port_props, I, O)
      throw(DomainError())
    end
    c = new()
    nports = I + O
    g = LG.DiGraph(nports)
    port_map = [Port(c, i) for i=1:nports]
    c.name = name
    c.port_map = port_map
    c.edges = g
    c.port_props = port_props
    c.sub_arrs = [c]
    c.sub_arr_vertices = [Vector{Int}(1:nports)]
    c
  end
end

"Not a reference"
RealArrow = Union{CompArrow, PrimArrow}

"Constructs CompArrow with where all input and output types are `Any`"
function CompArrow{I, O}(name::Symbol,
                        inp_names=[Symbol(:inp_, i) for i=1:I],
                        out_names=[Symbol(:out_, i) for i=1:O]) where {I, O}
  # Default is for first I ports to be in_ports then next O oout_ports
  in_port_props = [PortProps(true, inp_names[i], Any) for i = 1:I]
  out_port_props = [PortProps(false, out_names[i], Any) for i = 1:O]
  port_props = vcat(in_port_props, out_port_props)
  CompArrow{I, O}(name, port_props)
end


"port properties of *boundary* ports of arrow"
port_props(arr::CompArrow) = arr.port_props

"Name of a composite arrow"
name(arr::CompArrow) = arr.name

"A `Port` on a SubArrow"
struct SubPort{T <: Integer} <: AbstractPort
  parent::CompArrow # Parent arrow of arrow subport is attached to
  vertex_id::T
end

function string(port::SubPort)
  a = "SubArrow $(port.vertex_id) of $(name(parent(port))) - "
  b = string(deref(port))
  string(a, b)
end

print(io::IO, p::SubPort) = print(io, string(p))
show(io::IO, p::SubPort) = print(io, p)

"Parent of a `SubPort` is `parent` of attached `Arrow`"
parent(subport::SubPort) = subport.parent

"Is there a path between `sub_port1` and `sub_port2`"
function is_linked(subport1::SubPort, subport2::SubPort)::Bool
  same_parent = parent(subport1) == parent(subport2)
  if same_parent
    v1 = port_index(subport1)
    v2 = port_index(subport2)
    v1_component = weakly_connected_component(parent(subport1).edges, v1)
    v2 ∈ v1_component
  else
    false
  end
end

"Find the vertex index of this port in `arr edges"
port_index(port::SubPort)::Integer = port.vertex_id

"`PortProp`s of `subport` are `PortProp`s of `Port` it refers to"
port_props(subport::SubPort) = port_props(deref(subport))

"`SubPort` with vertex index `i` in arr.edges"
function port_index(arr::CompArrow, i::Integer)::SubPort
  nsubports = num_all_sub_ports(arr)
  if 1 <= i <= nsubports
    SubPort(arr, i)
  else
    throw(DomainError())
  end
end

"A component within a `CompArrow`"
struct SubArrow{I, O} <: ArrowRef{I, O}
  parent::CompArrow
  id::Int # `id`th sub_arrow in (some kind of) ordering of sub_arrows of `arr`
end

parent(sarr::SubArrow) = sarr.parent

"Dereference `arr` into `RealArrow`"
function deref(arr::SubArrow)
  newarr = arr.parent.sub_arrs[arr.id]
  @assert !is_ref(newarr)
  newarr
end

"Dereference `port`"
function deref(port::SubPort)::Port
  @assert is_ref(port)
  parent(port).port_map[port.vertex_id]
end

"ith sub arrow (reference) of `arr`"
function sub_arrow(arr::CompArrow, i::Integer)::SubArrow
  subarr = arr.sub_arrs[i]
  SubArrow{num_in_ports(subarr), num_out_ports(subarr)}(arr, i)
end

"Get (self) sub_arrow reference to `arr`"
sub_arrow(arr::CompArrow) = sub_arrow(arr, 1)

"sub_arrow which `port` is on"
function sub_arrow(port::SubPort)::SubArrow
  arr = parent(port)
  pid = port_index(port)
  # FIXME: Could speed this up easily
  id = findfirst(verts->pid ∈ verts, arr.sub_arr_vertices)
  sub_arrow(arr, id)
end

"Return all the sub_arrows of `arr` excluding arr itself"
sub_arrows(arr::CompArrow)::Vector{SubArrow} = all_sub_arrows(arr)[2:end]

"Return all the sub_arrows of `arr` including arr itself"
all_sub_arrows(arr::CompArrow)::Vector{SubArrow} =
  [sub_arrow(arr, i) for i = 1:num_all_sub_arrows(arr)]

"Number of sub_ports (inclusuive of boundary)"
num_all_sub_ports(arr::CompArrow) = length(arr.port_map)

"Number of sub_ports (exclusive of boundary)"
num_sub_ports{I, O}(arr::CompArrow{I, O}) = num_all_sub_ports(arr) - (I + O)

"All ports w/in `arr`: `⋃([ports(sa) for sa in all_sub_arrows(arr)])`"
all_sub_ports(arr::CompArrow)::Vector{SubPort} =
  [SubPort(arr, i) for i = 1:num_all_sub_ports(arr)]

"All ports w/in `arr`: `⋃([ports(sa) for sa in all_sub_arrows(arr)])`"
sub_ports{I, O}(arr::CompArrow{I, O})::Vector{SubPort} = all_sub_ports(arr)[I+O+1:end]

"All source (projecting) sub_ports"
src_sub_ports(arr::CompArrow)::Vector{SubPort} = filter(is_src, sub_ports(arr))

"All source (projecting) sub_ports"
all_src_sub_ports(arr::CompArrow)::Vector{SubPort} = filter(is_src, all_sub_ports(arr))

"All destination (receiving) sub_ports"
dst_sub_ports(arr::CompArrow)::Vector{SubPorts} = filter(is_dst, sub_ports(arr))

"All source (projecting) sub_ports"
all_dst_sub_ports(arr::CompArrow)::Vector{SubPort} = filter(is_dst, all_sub_ports(arr))

"is `port` a reference?"
is_ref(port::SubPort) = true

"Add a port inside the composite arrow"
function add_port!(arr::CompArrow, port::Port)::Port
  push!(arr.port_map, port)
  LG.add_vertex!(arr.edges)
  port
end

"Is `sport` a port on one of the `SubArrow`s within `arr`"
function in(sport::SubPort, arr::CompArrow)::Bool
  if parent(sport) == arr
    nsubports = num_all_sub_ports(arr)
    1 <= sport.vertex_id <= nsubports
  end
  false
end

"Is `port` within `arr` but not on boundary"
function strictly_in{I, O}(port::SubPort, arr::CompArrow{I, O})::Bool
  if parent(port) == arr
    nsubports = num_sub_ports(arr)
    return I + O < port.vertex_id <= I + O + nsubports
  end
  false
end

"Is `arr` a sub_arrow of composition `c_arr`"
in(arr::SubArrow, c_arr::CompArrow)::Bool = arr in all_sub_arrows(p)

"Number of sub_arrows in `c_arr` including `c_arr`"
num_all_sub_arrows(arr::CompArrow) = length(arr.sub_arrs)

"Number of sub_arrows"
num_sub_arrows(arr::CompArrow) = num_all_sub_arrows(arr) - 1

#FIXME Should this be `sub_ports`?
"All ports(references) of a sub_arrow(reference)"
ports(sarr::SubArrow)::Vector{SubPort} =
  [SubPort(sarr.parent, v_id) for v_id in sarr.parent.sub_arr_vertices[sarr.id]]

  #FIXME Should this be `sub_port`?
"Ith SubPort on `arr`"
port(arr::SubArrow, i::Integer)::SubPort = ports(arr)[i]

#FIXME Should this be `sub_port`?
"Ith SubPort on `arr`"
port(arr::SubArrow, name::Symbol)::SubPort = port(arr, port_id(name))

"Ensore we find the port"
must_find(i) = i == 0 ? throw(DomainError()) : i

"Get the id of a port from its name"
port_id(port::Arrow, name::Symbol) = must_find(findfirst(port_names(arr), name))

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

"Replace `sarr` with arr"
update_sub_arr!(sarr::SubArrow, arr::RealArrow) =
  sarr.parent.sub_arrs[sarr.id] = arr

"Edge between ports with a `CompArrow` for function composition"
Link = Tuple{SubPort, SubPort}

"All directed `Link`s (src_port, dst_port)"
function links(arr::CompArrow)::Vector{Link}
  es = LG.edges(arr.edges)
  map(e -> (port_index(arr, e.src), port_index(arr, e.dst)), LG.edges(arr.edges))
end

"Get parent of any `x ∈ xs` and check they all have the same parent"
function anyparent(xs::Vararg{<:Union{SubArrow, SubPort}})::CompArrow
  if !same(parent.(xs))
    println("Different parents!")
    throw(DomainError())
  end
  @show typeof(xs)
  parent(first(xs))
end

"Add an edge in CompArrow from port `l` to port `r`"
function link_ports!(l::SubPort, r::SubPort)
  c = anyparent(l, r)
  l_idx = port_index(l)
  r_idx = port_index(r)
  LG.add_edge!(c.edges, l_idx, r_idx)
end

"Is this `SubArrow` the parent of itself?"
self_parent(sarr::SubArrow) = parent(sarr) == deref(sarr)

link_ports!(l, r) =
  link_ports!(promote_left_port(l), promote_right_port(r))

promote_port(port::Port{<:CompArrow}) = SubPort(port.arrow, port.index)
promote_port(port::SubPort) = port

promote_left_port(port::SubPort) = promote_port(port)
promote_right_port(port::SubPort) = promote_port(port)
promote_left_port(port::Port) = promote_port(port)
promote_right_port(port::Port) = promote_port(port)

# # TODO: Check here and below that Port is valid boundary, i.e. port.arrow = c
# # TODO: DomainError not assert
# @assert parent(r) == c
src_port(srcarr, src_id) =
  self_parent(srcarr) ? in_port(srcarr, src_id) : out_port(srcarr, src_id)

dst_port(dst_arr, dst_id) =
  self_parent(dst_arr) ? out_port(dst_arr, dst_id) : in_port(dst_arr, dst_id)

promote_left_port(pid::Tuple{SubArrow, <:Integer}) = src_port(pid...)
promote_right_port(pid::Tuple{SubArrow, <:Integer}) = dst_port(pid...)

"Remove an edge in CompArrow from port `l` to port `r`"
function unlink_ports!(c::CompArrow, l::SubPort, r::SubPort)
  l_idx = port_index(l)
  r_idx = port_index(r)
  LG.rem_edge!(c.edges, l_idx, r_idx)
end

function unlink_ports!(l::SubPort, r::SubPort)
  c = anyparent(l, r)
  l_idx = port_index(l)
  r_idx = port_index(r)
  LG.rem_edge!(c.edges, l_idx, r_idx)
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
function lg_to_p(f::Function, port::SubPort)
  f(parent(port).edges, port_index(port))
end

"Helper for LightGraph API methods which return Vector{Port}, see `lg_to_p`"
function v_to_p(f::Function, port::SubPort)::Vector{SubPort}
  arr = parent(port)
  map(i->port_index(arr, i), lg_to_p(f, port))
end

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

"""Partition the ports into weakly connected equivalence classes"""
function weakly_connected_component(edges::LG.DiGraph, i::Integer)::Vector{Int}
  cc = weakly_connected_components(edges)
  filter(comp -> i ∈ comp, cc)[1]
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

"Should `port` be a src in context `arr`. Possibly false iff is_wired_ok = false"
function should_src(port::SubPort, arr::CompArrow)::Bool
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
function should_dst(port::SubPort, arr::CompArrow)::Bool
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
    if should_dst(port_index(arr, i), arr)
      # If it should be a desination
      if !(LG.indegree(arr.edges, i) == 1 &&
           LG.outdegree(arr.edges, i) == 0)
      # TODO: replace error with lens
        errmsg = """vertex $i Port $(port_index(arr, i)) should be a dst but
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
