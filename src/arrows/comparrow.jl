ArrowName = Symbol
VertexId = Integer

"A Port"
struct ProxyPort
  arrname::ArrowName  # Name of arrow it is a port on
  port_id::Int        # Position on arrow
end

mutable struct CompArrow <: Arrow
  name::ArrowName
  edges::LG.DiGraph
  port_to_vtx_id::Dict{ProxyPort, VertexId} # name(sarr) => vtxid of first port
  sarr_name_to_arrow::Dict{ArrowName, Arrow}
  port_props::Vector{PortProps}

  function CompArrow(name::Symbol,
                     port_props::Vector{PortProps})
    c = new()
    nports = length(port_props)
    g = LG.DiGraph(nports)
    c.name = name
    c.edges = g
    c.port_to_vtx_id = Dict(ProxyPort(name, i) => i for i = 1:nports)
    c.sarr_name_to_arrow = Dict(name => c)
    c.port_props = port_props
    c
  end
end

"A component within a `CompArrow`"
struct SubArrow <: ArrowRef
  parent::CompArrow
  name::ArrowName
  function SubArrow(parent::CompArrow, name::ArrowName)
    sarr = new(parent, name)
    if !is_valid(sarr)
      throw(DomainError())
    end
    sarr
  end
end

"`sarr` valid if it exists in its parent"
is_valid(sarr::SubArrow) = name(sarr) ∈ all_names(parent(sarr))

"A `Port` on a `SubArrow`"
struct SubPort <: AbstractPort
  sub_arrow::SubArrow  # Parent arrow of arrow sport is attached to
  port_id::Int     # this is ith `port` of parent
  function SubPort(sarr::SubArrow, port_id::Integer)
    if 0 < port_id <= num_ports(sarr)
      new(sarr, port_id)
    else
      println("Invalid port_id: ", port_id)
      throw(DomainError())
    end
  end
end

## Type Aliases ##

Link = Tuple{SubPort, SubPort}
PortMap = Dict{Port, Port}
PortIdMap = Dict{Int, Int}
PortSymbMap = Dict{Symbol, Symbol}
SubPortMap = Dict{SubPort, SubPort}

## CompArrow constructors
"Empty `CompArrow`"
CompArrow(name::ArrowName) = CompArrow(name, PortProps[])

"Constructs CompArrow with where all input and output types are `Any`"
function CompArrow(name::ArrowName, I::Integer, O::Integer)
  # Default is for first I ports to be in_ports then next O oout_ports
  inp_names = [Symbol(:inp_, i) for i=1:I]
  out_names = [Symbol(:out_, i) for i=1:O]
  in_port_props = [PortProps(true, inp_names[i], Any) for i = 1:I]
  out_port_props = [PortProps(false, out_names[i], Any) for i = 1:O]
  port_props = vcat(in_port_props, out_port_props)
  CompArrow(name, port_props)
end

"Constructs CompArrow with where all input and output types are `Any`"
function CompArrow(name::Symbol, inames::Vector{Symbol}, onames::Vector{Symbol})
  # Default is for first I ports to be in_ports then next O oout_ports
  in_port_props = [PortProps(true, iname, Any) for iname in inames]
  out_port_props = [PortProps(false, onames, Any) for onames in onames]
  port_props = vcat(in_port_props, out_port_props)
  CompArrow(name, port_props)
end

port_props(arr::CompArrow) = arr.port_props
port_props(sarr::SubArrow) = port_props(deref(sarr))

"Make `port` an in_port"
function make_in_port!(port::Port{<:CompArrow})
  port.arrow.port_props[port.port_id].is_in_port = true
end

"Make `port` an in_port"
function make_out_port!(port::Port{<:CompArrow})
  port.arrow.port_props[port.port_id].is_in_port = false
end

## Dereference ##

"Not a reference"
deref(sport::SubPort)::Port = port(deref(sport.sub_arrow), port_id(sport))
deref(sarr::SubArrow)::Arrow = arrow(parent(sarr), sarr.name)

"Get `Arrow` in `arr` with name `n`"
arrow(arr::CompArrow, n::ArrowName)::Arrow = arr.sarr_name_to_arrow[n]

## Naming ##

unique_sub_arrow_name()::ArrowName = gen_id()
name(arr::CompArrow)::ArrowName = arr.name
"Names of all `SubArrows` in `arr`, inclusive"

all_names(arr::CompArrow)::Vector{ArrowName} =
  collect(keys(arr.sarr_name_to_arrow))

"Names of all `SubArrows` in `arr`, exclusive of `arr`"
names(arr::CompArrow)::Vector{ArrowName} = setdiff(all_names(arr), [name(arr)])

"Rename `arr` to `n`"
function rename!(carr::CompArrow, n::ArrowName)::CompArrow
  # TODO make the name of the arrow fixed and remove this
  # That is, differentiate between arrname and subarrname
  # TODO CHECK NO NAME CONFLICTS
  arr = carr.sarr_name_to_arrow[carr.name]
  carr.sarr_name_to_arrow[carr.name]
  for (pxport, vtxid) in arr.port_to_vtx_id
    if pxport.arrname == carr.name
      delete!(arr.port_to_vtx_id, pxport)
      carr.port_to_vtx_id[ProxyPort(n, pxport.port_id)] = vtxid
    end
  end
  delete!(arr.sarr_name_to_arrow, carr.name)
  carr.sarr_name_to_arrow[n] = arr
  carr.name = n
  carr
end
## SubPort(s) constructors ##

"Construct a `SubPort` from a `ProxyPort`"
SubPort(arr::CompArrow, pxport::ProxyPort)::SubPort =
  SubPort(SubArrow(arr, pxport.arrname), pxport.port_id)

"`SubPort` of `arr` with vertex id `vtx_id`"
sub_port_vtx(arr::CompArrow, vtx_id::VertexId)::SubPort =
  SubPort(arr, rev(arr.port_to_vtx_id, vtx_id))

"`SubPort`s on boundary of `arr`"
sub_ports(arr::CompArrow) = sub_ports(sub_arrow(arr))

"`SubPort`s connected to `sarr`"
sub_ports(sarr::SubArrow)::Vector{SubPort} =
  [SubPort(sarr, i) for i=1:num_ports(sarr)]

"`SubPort` of `sarr` of number `port_id`"
sub_port(sarr::SubArrow, port_id::Integer) = SubPort(sarr, port_id)

"`SubPort` of `sarr` which is `port`"
function sub_port(sarr::SubArrow, port::Port)::SubPort
  port.arrow == deref(sarr) || throw(DomainError())
  sub_port(sarr, port.port_id)
end

"All the `SubPort`s of all `SubArrow`s on and within `arr`"
all_sub_ports(arr::CompArrow)::Vector{SubPort} =
  [SubPort(SubArrow(arr, pxp.arrname), pxp.port_id) for pxp in keys(arr.port_to_vtx_id)]

"`SubPort`s from `SubArrow`s within `arr` but not boundary"
inner_sub_ports(arr::CompArrow)::Vector{SubPort} =
  filter(sport -> !on_boundary(sport), all_sub_ports(arr))

"Number `SubPort`s within on on `arr`"
num_all_sub_ports(arr::CompArrow) = length(arr.port_to_vtx_id)

"Number `SubPort`s within on on `arr`"
num_sub_ports(arr::CompArrow) = num_all_sub_ports(arr) - num_ports(arr)

in_sub_ports(sarr::AbstractArrow)::Vector{SubPort} = filter(is_in_port, sub_ports(sarr))
out_sub_ports(sarr::AbstractArrow)::Vector{SubPort} = filter(is_out_port, sub_ports(sarr))
in_sub_port(sarr::AbstractArrow, i) = in_sub_ports(sarr)[i]
out_sub_port(sarr::AbstractArrow, i) = out_sub_ports(sarr)[i]

"is `sport` a boundary port?"
on_boundary(sport::SubPort)::Bool = name(parent(sport)) == name(sub_arrow(sport))

## Proxy Ports ##
all_proxy_ports(arr::CompArrow)::Vector{ProxyPort} = keys(arr.port_to_vtx_id)
proxy_ports(sarr::SubArrow) = [ProxyPort(name(sarr), i) for i=1:num_ports(sarr)]

## Add link remove SubArrs / Links ##

"Add a `SubArrow` `arr` to `CompArrow` `carr`"
function add_sub_arr!(carr::CompArrow, arr::Arrow)::SubArrow
  # TODO: FINISH!
  newname = unique_sub_arrow_name()
  carr.sarr_name_to_arrow[newname] = arr
  for (i, port) in enumerate(ports(arr))
    LG.add_vertex!(carr.edges)
    vtx_id = LG.nv(carr.edges)
    carr.port_to_vtx_id[ProxyPort(newname, i)] = vtx_id
  end
  SubArrow(carr, newname)
end

"Remove `sarr` from `parent(sarr)`, return updated Arrow"
function rem_sub_arr!(sarr::SubArrow)::Arrow
  if self_parent(sarr)
    println("Cannot replace parent subarrow")
    throw(DomainError())
  end
  arr = parent(sarr)

  # Remove every
  last_id = LG.nv(arr.edges)
  for pxport in proxy_ports(sarr)
    vtx_id = arr.port_to_vtx_id[pxport]
    # Remove the node and fix mess from node reordering
    LG.rem_vertex!(arr.edges, vtx_id) || throw("Could not remove node")
    # Whatever points to hte last node
    delete!(arr.port_to_vtx_id, pxport)
    if last_id != vtx_id
      to_update = rev(arr.port_to_vtx_id, last_id)
      arr.port_to_vtx_id[to_update] = vtx_id
    end
    last_id -= 1
  end

  delete!(arr.sarr_name_to_arrow, name(sarr))
  arr
end

"Add a port like (i.e. same `PortProps`) to carr"
function add_port!(carr::CompArrow, pprop::PortProps)::Port
  port_id = num_ports(carr) + 1
  LG.add_vertex!(carr.edges)
  vtx_id = LG.nv(carr.edges)
  carr.port_to_vtx_id[ProxyPort(name(carr), port_id)] = vtx_id
  push!(carr.port_props, pprop)
  Port(carr, port_id)
end

"Add a port like (i.e. same `PortProps`) to carr"
add_port_like!(carr::CompArrow, port::Port) = add_port!(carr, port_props(port))

"All directed `Link`s (src_port, dst_port)"
function links(arr::CompArrow)::Vector{Link}
  es = LG.edges(arr.edges)
  map(e -> (sub_port_vtx(arr, e.src), sub_port_vtx(arr, e.dst)), LG.edges(arr.edges))
end

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

"Is there a path between `SubPort`s `sport1` and `sport2`?"
function is_linked(sport1::SubPort, sport2::SubPort)::Bool
  same_parent = parent(sport1) == parent(sport2)
  if same_parent
    v1 = vertex_id(sport1)
    v2 = vertex_id(sport2)
    v1_component = weakly_connected_component(parent(sport1).edges, v1)
    v2 ∈ v1_component
  else
    false
  end
end

## Naming ##
name(sarr::SubArrow)::ArrowName = sarr.name
name(sport::SubPort) = Symbol(name(sub_arrow(sport)), :_, port_id(sport))

## Sub Arrow ##
num_all_sub_arrows(arr::CompArrow) = length(all_sub_arrows(arr))
num_sub_arrows(arr::CompArrow) = length(sub_arrows(arr))


"`SubArrow` of `arr` with name `n`"
sub_arrow(arr::CompArrow, n::ArrowName)::SubArrow = SubArrow(arr, n)

"All `SubArrows` within `arr`, inclusive"
all_sub_arrows(arr::CompArrow)::Vector{SubArrow} =
  [SubArrow(arr, n) for n in all_names(arr)]

"All `SubArrow`s within `arr` exlusive of `arr`"
sub_arrows(arr::CompArrow)::Vector{SubArrow} =
  [SubArrow(arr, n) for n in names(arr)]

"`SubArrow` which `sport` is 'attached' to"
sub_arrow(sport::SubPort)::SubArrow = sport.sub_arrow

"(self) sub_arrow reference to `arr`"
sub_arrow(arr::CompArrow) = sub_arrow(arr, name(arr))

parent(sarr::SubArrow)::CompArrow = sarr.parent
parent(sarr::SubPort)::CompArrow = parent(sub_arrow(sarr))

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
  map(i->sub_port_vtx(arr, i), lg_to_p(f, port))
end

"`sport` is number `port_id(sport)` `SubPort` on `sub_arrow(sport)`"
port_id(sport::SubPort)::Integer = sport.port_id

# Not in minimal integeral #########################################
vertex_id(sport::SubPort)::VertexId =
  parent(sport).port_to_vtx_id[ProxyPort(sport.sub_arrow.name, sport.port_id)]
