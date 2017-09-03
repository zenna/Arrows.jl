ArrowName = name
# Need ProxyPort because julia has no cyclical types, otherwise use `Port`
ProxyPort = Tuple{ArrowName, Integer}
VertexId = Integer

mutable struct CompArrow{I, O} <: Arrow{I, O}
  name::ArrowName
  edges::LG.DiGraph
  port_to_vtx_id::Dict{ProxyPort, VertexId} # name(sarr) => vtxid of first port
  sarr_name_to_arrow::Dict{ArrowName, RealArrow}
  port_props::Vector{PortProps}
end

function CompArrow{I, O}(name::Symbol, port_props::Vector{PortProps})
  if !is_valid(port_props, I, O)
    throw(DomainError())
  end
  c = new()
  nports = I + O
  g = LG.DiGraph(nports)
  c.name = name
  c.edges = g
  c.port_to_vtx_id = Dict((name, i) => i for i = 1:I+O)
  c.sarr_name_to_arrow = Dict(name => c)
  c.port_props = port_props
end

unique_sub_arrow_name()::ArrowName = gen_id()
name(arr::CompArrow)::ArrowName = arr.name
SubPort(arr::CompArrow, pxport::ProxyPort)::SubPort =
  SubPort(SubArrow(arr, pxport[1]), pxport[2])

"`SubPort` of `arr` with vertex id `vtx_id`"
function sub_port(arr::CompArrow, vtx_id::VertexId)::SubPort
  SubPort(arr, rev(arr.port_to_vtx_id, vtx_id))
end

"Add a `SubArrow` `arr` to `CompArrow` `carr`"
function add_sub_arr!{I, O}(carr::CompArrow, arr::RealArrow{I, O})::Arrow
  # TODO: FINISH!
  newname = unique_sub_arrow_name()
  carr.sarr_name_to_arrow[newname] = arr
  for port in ports(arr)
    LG.add_vertex!(carr.edges)
    vtx_id = LG.nv(carr.edges)
    pxport = (newname, i)
    carr.port_to_vtx_id[pxport] = pxport
  end
  carr
end

"Remove a `SubArrow` from a `CompArrow`"
function rem_sub_arr!(carr::CompArrow, sarr::SubArrow)::CompArrow
  if sarr ∉ sub_arrows(carr)
    println("Cannot remove subarrow because its not in composition")
  end
  delete!(carr.sub_arrow_index[sarr.name])
  delete!(carr.sub_arrow_arrow[sarr.name])
  # Delete the edges sub_arrow_index[sarr.name] .. + ndhada
  carr
end

Link = Tuple{SubPort, SubPort}

"All directed `Link`s (src_port, dst_port)"
function links(arr::CompArrow)::Vector{Link}
  es = LG.edges(arr.edges)
  map(e -> (sub_port(arr, e.src), sub_port(arr, e.dst)), LG.edges(arr.edges))
end

# Not minimal
num_all_sub_arrows(arr::CompArrow) = length(all_sub_arrows(arr))
num_sub_arrows(arr::CompArrow) = length(sub_arrows(arr))

"A component within a `CompArrow`"
struct SubArrow
  parent::CompArrow
  name::ArrowName
end

parent(sarr::SubArrow) = sarr.parent
name(sarr::SubArrow) = sarr.name
deref(sarr::SubArrow) = sarr.parent.sub_arrow_arrow[sarr.name]
all_sub_arrows(arr::CompArrow)::Vector{SubArrow} =
  [SubArrow(arr, n) for n in keys(arr.sub_arrow_index)]

sub_arrows(arr::CompArrow)::Vector{SubArrow} = @assert false # [SubArrow(arr, n) for n in keys(arr.sub_arrow_index)]

"Add an edge in CompArrow from port `l` to port `r`"
function link_ports!(l::SubPort, r::SubPort)
  c = anyparent(l, r)
  l_idx = vertex_id(l)
  r_idx = vertex_id(r)
  LG.add_edge!(c.edges, l_idx, r_idx)
  # TODO: error handling
end

"Remove an edge in CompArrow from port `l` to port `r`"
function unlink_ports!(l::SubPort, r::SubPort)
  c = anyparent(l, r)
  l_idx = vertex_id(l)
  r_idx = vertex_id(r)
  LG.rem_edge!(c.edges, l_idx, r_idx)
  # TODO: error handling
end

"""
Helper function to translate LightGraph functions to Port functions
  f: LightGraph API function f(g::Graph, v::VertexId)
  port: port corresponding to vertex to which f(v) is applied
  arr: Parent Composite arrow
"""
function lg_to_p(f::Function, port::SubPort)
  f(parent(port).edges, vertex_id(port))
end

"Helper for LightGraph API methods which return Vector{Port}, see `lg_to_p`"
function v_to_p(f::Function, port::SubPort)::Vector{SubPort}
  arr = parent(port)
  map(i->vertex_id(arr, i), lg_to_p(f, port))
end

# Not minimal ##################################################
in(sarr::SubArrow, arr::CompArrow) = sarr ∈ sub_arrows(arr)

"A `Port` on a `SubArrow`"
struct SubPort <: AbstractPort
  sub_arrow::SubArrow # Parent arrow of arrow sport is attached to
  port_id::T     # this is ith `port` of parent
end

port_id(sport::SubPort)::Integer = sarr.port_id
sub_arrow(sport::SubPort)::SubArrow = sub_arrow.sub_arrow
"Get (self) sub_arrow reference to `arr`"
sub_arrow(arr::CompArrow) = sub_arrow(arr, name(arr))

# Not in minimal integeral #########################################
parent(sarr::SubPort)::CompArrow = parent(sub_arrow(sarr))
vertex_id(sport::SubPort)::Integer = parent(sport) + sport.port_id - 1
deref(sport::SubPort)::Port = port(deref(parent(sport)), port_id(sport))
