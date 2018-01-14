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
  vtx_id_to_port::Vector{ProxyPort}         # ProxyPort at vtx_id
  props::Vector{Props}
  sarr_name_to_arrow::Dict{ArrowName, Arrow}
  sarr_name_to_sarrow::Dict{ArrowName, ArrowRef}

  function CompArrow(nm::Symbol,
                     props::Vector{Props}, nports::Number)
    !hasduplicates(name.(props)) || throw(ArgumentError("name duplicates: $(name.(props))"))
    c = new()
    g = LG.DiGraph(nports)
    c.name = nm
    c.edges = g
    c.vtx_id_to_port = [ProxyPort(nm, i) for i = 1:nports]
    c.port_to_vtx_id = Dict(c.vtx_id_to_port[i] => i
                              for i = 1:nports)
    c.sarr_name_to_arrow = Dict(nm => c)
    c.sarr_name_to_sarrow = Dict()
    c.props = props
    c
  end
end

"A component within a `CompArrow`"
struct SubArrow{A} <: ArrowRef
  parent::CompArrow
  name::ArrowName
  # This parameter should be unnecessary
  function SubArrow(parent::T, name::ArrowName) where T<:CompArrow
    arr = arrow(parent, name)
    sarr = new{typeof(arr)}(parent, name)
    if !is_valid(sarr)
      throw(ArgumentError("Invalid SubArrow: name not in parent"))
    end
    sarr
  end
end

"Constructor to avoid circularity between `Arrow` and `SubArrow`"
function CompArrow(nm::Symbol, props::Vector{Props})::CompArrow
  nports = length(props)
  carr = CompArrow(nm, props, nports)
  sarr = SubArrow(carr, nm)
  carr.sarr_name_to_sarrow[nm] = sarr
  carr
end

## Validation ##

"`sarr` valid if it exists in its parent"
is_valid(sarr::SubArrow) = name(sarr) ∈ parent(sarr)

"A `Port` on a `SubArrow`"
struct SubPort <: AbstractPort
  sub_arrow::SubArrow  # Parent arrow of arrow sport is attached to
  port_id::Int     # this is ith `port` of parent
  function SubPort(sarr::SubArrow, port_id::Integer)
    if 0 < port_id <= num_ports(sarr)
      new(sarr, port_id)
    else
      throw(ArgumentError("Invalid port_id: $port_id"))
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
  to_delete = filter((pxport, vtx_id) -> pxport.arrname == carr.name,
                          arr.port_to_vtx_id)
  for (pxport, vtxid) in to_delete
    delete!(arr.port_to_vtx_id, pxport)
    new_pport = ProxyPort(n, pxport.port_id)
    carr.vtx_id_to_port[vtxid] = new_pport
    carr.port_to_vtx_id[new_pport] = vtxid
  end
  delete!(arr.sarr_name_to_arrow, carr.name)
  delete!(arr.sarr_name_to_sarrow, carr.name)
  carr.sarr_name_to_arrow[n] = arr
  carr.sarr_name_to_sarrow[n] = SubArrow(arr, n)
  carr.name = n
  carr
end

## SubPort(s) constructors ##

"Construct a `SubPort` from a `ProxyPort`"
SubPort(arr::CompArrow, pxport::ProxyPort)::SubPort =
  SubPort(sub_arrow(arr, pxport.arrname), pxport.port_id)

"`SubPort` of `arr` with vertex id `vtx_id`"
sub_port_vtx(arr::CompArrow, vtx_id::VertexId)::SubPort =
  SubPort(arr, arr.vtx_id_to_port[vtx_id])

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
  if port.arrow != deref(sarr)
    throw(ArgumentError("Port not on SubArrow"))
  end
  sub_port(sarr, port.port_id)
end

"`SubPort` corresponding to `prt` on (self) `SubArrow` of `prt.arrow`"
sub_port(prt::Port)::SubPort = SubPort(sub_arrow(prt.arrow), prt.port_id)

"All the `SubPort`s of all `SubArrow`s on and within `arr`"
function all_sub_ports(arr::CompArrow)::Vector{SubPort}
  # TODO: Make subarrow sorting more principled
  sorted_keys = sort(arr.vtx_id_to_port,
                     lt=(p1, p2) -> p1.arrname < p2.arrname)
  [SubPort(arr, pxp) for pxp in sorted_keys]
end

"`SubPort`s from `SubArrow`s within `arr` but not boundary"
inner_sub_ports(arr::CompArrow)::Vector{SubPort} =
  filter(sport -> !on_boundary(sport), all_sub_ports(arr))

"Number `SubPort`s within on on `arr`"
num_all_sub_ports(arr::CompArrow) = length(arr.vtx_id_to_port)

"Number `SubPort`s within on on `arr`"
num_sub_ports(arr::CompArrow) = num_all_sub_ports(arr) - num_ports(arr)

in_sub_ports(sarr::AbstractArrow)::Vector{SubPort} = filter(is_in_port, sub_ports(sarr))
out_sub_ports(sarr::AbstractArrow)::Vector{SubPort} = filter(is_out_port, sub_ports(sarr))
in_sub_port(sarr::AbstractArrow, i) = in_sub_ports(sarr)[i]
out_sub_port(sarr::AbstractArrow, i) = out_sub_ports(sarr)[i]

"is `sport` a boundary port?"
on_boundary(sport::SubPort)::Bool = name(parent(sport)) == name(sub_arrow(sport))

## Proxy Ports ##

all_proxy_ports(arr::CompArrow)::Vector{ProxyPort} = arr.vtx_id_to_port
proxy_ports(sarr::SubArrow) = [ProxyPort(name(sarr), i) for i=1:num_ports(sarr)]

## Ports of SubArrows ##
ports(sarr::SubArrow)::Vector{Port} = ports(deref(sarr))

## Add link remove SubArrs / Links ##
"Add a `SubArrow` `arr` to `CompArrow` `carr`"
function add_sub_arr!(carr::CompArrow, arr::Arrow)::SubArrow
  # TODO: FINISH!
  newname = unique_sub_arrow_name()
  carr.sarr_name_to_arrow[newname] = arr
  sarr = SubArrow(carr, newname)
  carr.sarr_name_to_sarrow[newname] = sarr
  for (i, port) in enumerate(ports(arr))
    add_port_lg!(carr, newname, i)
  end
  sarr
end

"Remove `pxport` from a `CompArrow`"
function rem_pxport!(pxport::ProxyPort, carr::CompArrow)
  # This section replicates the logic of LG.rem_vertex!(arr.edges, vtx_id)
  # <quote>This operation has to be performed carefully if one keeps external
  # data structures indexed by edges or vertices in the graph, since
  # internally the removal is performed swapping the vertices v and |V|,
  # and removing the last vertex |V| from the graph. After removal the
  # vertices in g will be indexed by 1:|V|-1.</quote>
  vtx_id = carr.port_to_vtx_id[pxport]
  last_id = LG.nv(carr.edges)
  to_update = carr.vtx_id_to_port[last_id]
  carr.vtx_id_to_port[vtx_id] = to_update
  carr.port_to_vtx_id[to_update] = vtx_id
  LG.rem_vertex!(carr.edges, vtx_id) || throw("Could not remove node")
  deleteat!(carr.vtx_id_to_port, last_id)
  delete!(carr.port_to_vtx_id, pxport)
  carr
end

"Remove `prt` from a `CompArrow`"
function rem_port!(prt::Port{<:CompArrow})
  carr = prt.arrow
  pxport = ProxyPort(name(carr), prt.port_id) # FIXME
  rem_pxport!(pxport, carr)
  deleteat!(carr.props, prt.port_id)
  carr
end

"Remove `sarr` from `parent(sarr)`, return updated Arrow"
function rem_sub_arr!(sarr::SubArrow)::Arrow
  if self_parent(sarr)
    throw(ArgumentError("Cannot replace parent subarrow"))
  end
  arr = parent(sarr)

  # Remove every ...?
  for pxport in copy(proxy_ports(sarr))
    rem_pxport!(pxport, arr)
  end

  delete!(arr.sarr_name_to_arrow, name(sarr))
  delete!(arr.sarr_name_to_sarrow, name(sarr))
  arr
end

"Helper function for the addition of ports that handle the calls to LightGraph"
function add_port_lg!(carr::CompArrow, arrname::ArrowName, port_id::Int)
  LG.add_vertex!(carr.edges)
  vtx_id = LG.nv(carr.edges)
  pxport = ProxyPort(arrname, port_id)
  push!(carr.vtx_id_to_port, pxport)
  @assert length(carr.vtx_id_to_port) == vtx_id
  carr.port_to_vtx_id[pxport] = vtx_id
end

"Add a port like (i.e. same `Props`) to carr"
function add_port!(carr::CompArrow, prps::Props)::Port
  name(prps) ∉ name.(⬧(carr)) || throw(ArgumentError("$(name(prps)) ∈ carr"))
  port_id = num_ports(carr) + 1
  add_port_lg!(carr, name(carr), port_id)
  push!(carr.props, deepcopy(prps))
  Port(carr, port_id)
end

"Add a port like `prt` (i.e. same `Props`) to carr"
function add_port_like!(carr::CompArrow, prt::Port, genname=true)
  prps = deepcopy(props(prt)) # FIXME: Copying prps twice, here and add_port!
  if genname && name(prt) ∈ name.(⬧(carr))
    nm = uniquename(name(prt).name, [nm.name for nm in name.(⬧(carr))])
    setprop!(Name(nm), prps)
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
  # FIXME: should_src is slow
  # pre Disabled because invert does wrong way #90
  # should_src(l) && should_dst(r) || throw(ArgumentError("only link src to dist but l = $l r = $r"))
  c = anyparent(l, r)
  l_idx = vertex_id(l)
  r_idx = vertex_id(r)
  LG.add_edge!(c.edges, l_idx, r_idx)
  # TODO: error handling
end

⥅(l, r) = link_ports!(l, r)
⥆(l, r) = link_ports!(r, l)

"Remove an edge in CompArrow from port `l` to port `r`, `true` iff success"
function unlink_ports!(l::SubPort, r::SubPort)::Bool
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
function sub_arrow(arr::CompArrow, name::ArrowName)::SubArrow
  arr.sarr_name_to_sarrow[name]
end

"All `SubArrows` within `arr`, inclusive"
function all_sub_arrows(arr::CompArrow)::Vector{SubArrow}
  (collect ∘ values)(arr.sarr_name_to_sarrow)
end

"All `SubArrow`s within `arr` exlusive of `arr`"
sub_arrows(arr::CompArrow)::Vector{SubArrow} =
  [sub_arrow(arr, n) for n in names(arr)]

"`SubArrow` which `sport` is 'attached' to"
sub_arrow(sport::SubPort)::SubArrow = sport.sub_arrow

"(self) sub_arrow reference to `arr`"
sub_arrow(arr::CompArrow) = sub_arrow(arr, name(arr))

"`CompArrow` that `sarr` is component in"
parent(sarr::SubArrow)::CompArrow = sarr.parent

"`CompArrow` that `sub_arrow(sprt)` is component in"
parent(sprt::SubPort)::CompArrow = parent(sub_arrow(sprt))

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
port_id(sprt::SubPort)::Integer = sprt.port_id

# Not in minimal integeral #########################################
vertex_id(sport::SubPort)::VertexId =
  parent(sport).port_to_vtx_id[ProxyPort(sport.sub_arrow.name, sport.port_id)]
