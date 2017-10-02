ArrowName = Symbol
VertexId = Integer

"A Port"
struct ProxyPort
  arrname::ArrowName  # Name of arrow it is a port on
  port_id::Int        # Position on arrow
end

"""A Composite Arrow: An `Arrow` composed of multiple `Arrow`s"""
mutable struct CompArrow <: Arrow
  name::ArrowName
  edges::LG.DiGraph
  port_to_vtx_id::Dict{ProxyPort, VertexId} # name(sarr) => vtxid of first port
  props::Vector{Props}
  sarr_name_to_arrow::Dict{ArrowName, Arrow}

  function CompArrow(nm::Symbol,
                     props::Vector{Props})
    !hasduplicates(name.(props)) || throw(ArgumentError("name duplicates: $(name.(props))"))
    c = new()
    nports = length(props)
    g = LG.DiGraph(nports)
    c.name = nm
    c.edges = g
    c.port_to_vtx_id = Dict(ProxyPort(nm, i) => i for i = 1:nports)
    c.sarr_name_to_arrow = Dict(nm => c)
    c.props = props
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
      throw(ArgumentError("Invalid SubArrow: name not in parent"))
    end
    sarr
  end
end

## Validation ##

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

## CompArrow constructors ##
"Empty `CompArrow`"
CompArrow(name::ArrowName) = CompArrow(name, Props[])

"Constructs CompArrow with where all input and output types are `Any`"
function CompArrow(name::ArrowName, I::Integer, O::Integer)
  # Default is for first I ports to be in_ports then next O oout_ports
  inames = [Symbol(:inp_, i) for i=1:I]
  onames = [Symbol(:out_, i) for i=1:O]
  in_props = [Props(true, inames[i], Any) for i = 1:I]
  out_props = [Props(false, onames[i], Any) for i = 1:O]
  props = vcat(in_props, out_props)
  CompArrow(name, props)
end

"Constructs CompArrow with where all input and output types are `Any`"
function CompArrow(name::Symbol, inames::Vector{Symbol}, onames::Vector{Symbol})
  # Default is for first I ports to be in_ports then next O oout_ports
  in_props = [Props(true, iname, Any) for iname in inames]
  out_props = [Props(false, onames, Any) for onames in onames]
  props = vcat(in_props, out_props)
  CompArrow(name, props)
end

"Port Properties of all ports of `arr`"
props(arr::CompArrow) = arr.props

"Port Properties of all ports of `sarr`"
props(sarr::SubArrow) = props(deref(sarr))

# DEPRECATE
"Make `port` an in_port"
function set_in_port!(prt::Port{<:CompArrow})
  setprop!(In(), props(prt))
end

# DEPRECATE
"Make `port` an in_port"
function make_out_port!(prt::Port{<:CompArrow})
  setprop!(Out(), props(prt))
end

## Dereference ##

"`Port` that `sport` is reference to"
deref(sport::SubPort)::Port = port(deref(sport.sub_arrow), port_id(sport))

"`Arrow` that `sarr` is reference to"
deref(sarr::SubArrow)::Arrow = arrow(parent(sarr), sarr.name)

"`Arrow` in `arr` with name `n`"
arrow(arr::CompArrow, n::ArrowName)::Arrow = arr.sarr_name_to_arrow[n]

## Naming ##

"globally unique `ArrowName`"
unique_sub_arrow_name()::ArrowName = gen_id()

"ArrowName of `carr`"
name(carr::CompArrow)::ArrowName = carr.name

"Names of all `SubArrows` in `arr`, inclusive"
all_names(arr::CompArrow)::Vector{ArrowName} =
  sort(collect(keys(arr.sarr_name_to_arrow)))

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

"i`th `SubPort` on boundary of `arr`"
sub_port(carr::CompArrow, i::Integer)::SubPort = sub_ports(carr)[i]

"`SubPort`s connected to `sarr`"
sub_ports(sarr::SubArrow)::Vector{SubPort} =
  [SubPort(sarr, i) for i=1:num_ports(sarr)]

"`SubPort` of `sarr` of number `port_id`"
sub_port(sarr::SubArrow, port_id::Integer) = SubPort(sarr, port_id)

"`SubPort` of `sarr` which is `port`"
function sub_port(sarr::SubArrow, port::Port)::SubPort
  port.arrow == deref(sarr) || throw(ArgumentError("Port not on SubArrow"))
  sub_port(sarr, port.port_id)
end

"`SubPort` corresponding to `prt` on (self) `SubArrow` of `prt.arrow`"
sub_port(prt::Port)::SubPort = SubPort(sub_arrow(prt.arrow), prt.port_id)

"All the `SubPort`s of all `SubArrow`s on and within `arr`"
function all_sub_ports(arr::CompArrow)::Vector{SubPort}
  # TODO: Make subarrow sorting more principled
  sorted_keys = sort(collect(keys(arr.port_to_vtx_id)),
                     lt=(p1, p2) -> p1.arrname < p2.arrname)
  [SubPort(SubArrow(arr, pxp.arrname), pxp.port_id) for pxp in sorted_keys]
end

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

## Ports of SubArrows ##
ports(sarr::SubArrow)::Vector{Port} = ports(deref(sarr))

## Add link remove SubArrs / Links ##
"Add a `SubArrow` `arr` to `CompArrow` `carr`"
function add_sub_arr!(carr::CompArrow, arr::Arrow)::SubArrow
  # TODO: FINISH!
  newname = unique_sub_arrow_name()
  carr.sarr_name_to_arrow[newname] = arr
  for (i, port) in enumerate(ports(arr))
    add_port_lg!(carr, newname, i)
  end
  SubArrow(carr, newname)
end

"Remove `prt` from a `CompArrow`"
function rem_port!(prt::Port{<:CompArrow})
  carr = prt.arrow
  pxport = ProxyPort(name(carr), prt.port_id) # FIXME
  vtx_id = carr.port_to_vtx_id[pxport]
  last_id = LG.nv(carr.edges)
  LG.rem_vertex!(carr.edges, vtx_id) || throw("Could not remove node")
  delete!(carr.port_to_vtx_id, pxport)
  if last_id != vtx_id
    to_update = rev(carr.port_to_vtx_id, last_id)
    carr.port_to_vtx_id[to_update] = vtx_id
  end
  deleteat!(carr.props, prt.port_id)
  carr
end

"Remove `sarr` from `parent(sarr)`, return updated Arrow"
function rem_sub_arr!(sarr::SubArrow)::Arrow
  if self_parent(sarr)
    throw(ArgumentError("Cannot replace parent subarrow"))
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

"Add a port like (i.e. same `Props`) to carr"
function add_port!(carr::CompArrow, prps::Props)::Port
  name(prps) ∉ name.(⬧(carr)) || throw(ArgumentError("$(name(prps)) ∈ carr"))
  port_id = num_ports(carr) + 1
  add_port_lg!(carr, name(carr), port_id)
  push!(carr.props, deepcopy(prps))
  Port(carr, port_id)
end

"Helper function for the addition of ports that handle the calls to LightGraph"
function add_port_lg!(carr::CompArrow, arrname::ArrowName, port_id::Int)
  LG.add_vertex!(carr.edges)
  vtx_id = LG.nv(carr.edges)
  carr.port_to_vtx_id[ProxyPort(arrname, port_id)] = vtx_id
end

"Add a port like (i.e. same `Props`) to carr"
function add_port_like!(carr::CompArrow, prt::Port, genname=true)
  prps = deepcopy(props(prt)) # FIXME: Copying prps twice, here and add_port!
  if genname && name(prt) ∈ name.(⬧(carr))
    typeof(name(prt))
    nm = uniquename(name(prt), name.(⬧(carr)))
    setprop!(nm, prps)
  end
  add_port!(carr, prps)
end

"All directed `Link`s (src_port, dst_port)"
function links(arr::CompArrow)::Vector{Link}
  es = LG.edges(arr.edges)
  map(e -> (sub_port_vtx(arr, e.src), sub_port_vtx(arr, e.dst)), es)
end

"Add an edge in CompArrow from port `l` to port `r`"
function link_ports!(l::SubPort, r::SubPort)
  c = anyparent(l, r)
  l_idx = vertex_id(l)
  r_idx = vertex_id(r)
  LG.add_edge!(c.edges, l_idx, r_idx)
  # TODO: error handling
end

⥅(l, r) = link_ports!(l, r)
⥆(l, r) = link_ports!(r, l)

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
