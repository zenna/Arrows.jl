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
                           port_props::Vector{PortProps}) where {I, O}
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

"Edge between ports with a `CompArrow` for function composition"
Link = Tuple{SubPort, SubPort}

"All directed `Link`s (src_port, dst_port)"
function links(arr::CompArrow)::Vector{Link}
  es = LG.edges(arr.edges)
  map(e -> (port_index(arr, e.src), port_index(arr, e.dst)), LG.edges(arr.edges))
end

"Add an edge in CompArrow from port `l` to port `r`"
function link_ports!(l::SubPort, r::SubPort)
  c = anyparent(l, r)
  l_idx = port_index(l)
  r_idx = port_index(r)
  LG.add_edge!(c.edges, l_idx, r_idx)
end

"Remove an edge in CompArrow from port `l` to port `r`"
function unlink_ports!(l::SubPort, r::SubPort)
  c = anyparent(l, r)
  l_idx = port_index(l)
  r_idx = port_index(r)
  LG.rem_edge!(c.edges, l_idx, r_idx)
end

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

"Is there a path between `SubPort`s `sport1` and `sport2`?"
function is_linked(sport1::SubPort, sport2::SubPort)::Bool
  same_parent = parent(sport1) == parent(sport2)
  if same_parent
    v1 = port_index(sport1)
    v2 = port_index(sport2)
    v1_component = weakly_connected_component(parent(sport1).edges, v1)
    v2 ∈ v1_component
  else
    false
  end
end

"Find the vertex index of this port in `arr edges"
port_index(port::SubPort)::Integer = port.vertex_id

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

"Add a port inside the composite arrow"
function add_port!(arr::CompArrow, port::Port)::Port
  push!(arr.port_map, port)
  LG.add_vertex!(arr.edges)
  port
end

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
