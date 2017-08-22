import LightGraphs: Graph, add_edge!, add_vertex!, connected_components,
  weakly_connected_components, rem_edge!

"Directed Composite Arrow"
type CompArrow{I, O} <: Arrow{I, O}
  name::Symbol                  # name of CompArrow
  id::Symbol                    # Unique id
  edges::LG.DiGraph    # Graph over port indices - each port unique id
  port_map::Vector{Port}        # port_map[i] is `Port` with index i in `edges`
  port_attrs::Vector{PortAttrs} # Mapping from border port to attributes


  function CompArrow{I, O}(name::Symbol, port_attrs::Vector{PortAttrs}) where{I, O}
    if !is_valid_port_attrs(port_attrs, I, O)
      throw(DomainError())
    end
    c = new()
    nports = I + O
    g = LG.DiGraph(nports)
    port_map = [Port(c, i) for i=1:nports]
    c.name = name
    c.id = gen_id()
    c.port_map = port_map
    c.edges = g
    c.port_attrs = port_attrs
    c
  end
end

"Constructs CompArrow with Any"
function CompArrow{I, O}(name::Symbol) where {I, O}
  # Default is for first I ports to be in_ports then next O oout_ports
  in_port_attrs = [PortAttrs(true, Symbol(:inp_, i), Any) for i = 1:I]
  out_port_attrs = [PortAttrs(false, Symbol(:out_, i), Any) for i = 1:O]
  port_attrs = vcat(in_port_attrs, out_port_attrs)
  CompArrow{I, O}(name, port_attrs)
end

name(arr::CompArrow) = arr.name

"Return all the sub_arrows of `arr` excluding arr itself"
function sub_arrows(arr::CompArrow)::Vector{Arrow}
  unique([port.arrow for port in arr.port_map if port.arrow != arr])
end

"All ports w/in `arr`: `⋃([ports(sa) for sa in all_sub_arrows(arr)])`"
sub_ports(arr::CompArrow) = [port_index(arr, i) for i = 1:LG.nv(arr.edges)]

"All projecting sub_ports"
src_sub_ports(arr::CompArrow) = filter(port->is_src(port, arr), sub_ports(arr))

"All receiving sub_ports"
dest_sub_ports(arr::CompArrow) = filter(port->is_dest(port, arr), sub_ports(arr))

"Return all the sub_arrows of `arr` including arr itself"
function all_sub_arrows(arr::CompArrow)::Vector{Arrow}
  unique([port.arrow for port in arr.port_map])
end

"Find the index of this port in c edg es"
function port_index(arr::CompArrow, port::Port)::Integer
  index = findfirst(arr.port_map, port)
  if index > 0
    index
  else
    throw(DomainError())
  end
end

"The Port with index `i` in arr.edges"
port_index(arr::CompArrow, i::Integer)::Port = arr.port_map[i]

function port_attrs(arr::CompArrow, port::Port)
  arr.port_attrs[port_index(port.arrow, port)]
end

"Add a port inside the composite arrow"
function add_port!(arr::CompArrow, port::Port)::Port
  push!(arr.port_map, port)
  add_vertex!(arr.edges)
  port
end

"Add a port to `arr` with same attributes as `port`"
add_port_like!(arr::CompArrow, port::Port)::Port = add_port!(arr, port_attrs(port))

"Is `port` within `arr`"
in(port::Port, arr::CompArrow)::Bool = port in arr.port_map

# FIXME this searches over many duplicates
"Is `arr` a sub_arrow of composition `c_arr`"
in(arr::Arrow, c_arr::CompArrow)::Bool = arr in (p.arrow for p in c_arr.port_map)

"Add a sub_arrow `arr` to composition `c_arr`"
function add_sub_arr!(c_arr::CompArrow, arr::Arrow)::Arrow
  if arr in c_arr
    throw(DomainError())
  else
    for port in ports(arr)
      add_port!(c_arr, port)
    end
    arr
  end
end

"Add an edge in CompArrow from port `l` to port `r`"
function link_ports!(c::CompArrow, l::Port, r::Port)
  l_idx = port_index(c, l)
  r_idx = port_index(c, r)
  add_edge!(c.edges, l_idx, r_idx)
end

""" Add edge in `c` `src_id`th projecting port of `src_arr` to
`dest_id`receiving port of `dest_arr`"""
function link_ports!(c::CompArrow, src_arr::Arrow, src_id::Integer,
                     dest_arr::Arrow, dest_id::Integer)
  src_port = src_arr == c ? in_port(src_arr, src_id) : out_port(src_arr, src_id)
  dest_port = dest_arr == c ? out_port(dest_arr, dest_id) : in_port(dest_arr, dest_id)
  link_ports!(c, src_port, dest_port)
end

"Remove an edge in CompArrow from port `l` to port `r`"
function unlink_ports!(c::CompArrow, l::Port, r::Port)
  l_idx = port_index(c, l)
  r_idx = port_index(c, r)
  rem_edge!(c.edges, l_idx, r_idx)
end

# Graph traversal
"is vertex `v` a destination, i.e. does it project more than 0 edges"
is_dest(g::LG.DiGraph, v::Integer) = LG.indegree(g, v) > 0

"is vertex `v` a source, i.e. does it receive more than 0 edges"
is_src(g::LG.DiGraph, v::Integer) = LG.outdegree(g, v) > 0

#FIXME: Turn this into a macro for type stability
"Helper function to translate LightGraph functions to Port functions"
function lg_to_p(f::Function, port::Port, arr::CompArrow)
  f(arr.edges, port_index(arr, port))
end

function v_to_p(f::Function, port::Port, arr::Arrow)
  map(i->port_index(arr, i), lg_to_p(f, port, arr))
end

"Is port a destination. i.e. does corresponding vertex project more than 0"
is_dest(port::Port, arr::CompArrow) = lg_to_p(is_dest, port, arr)

"Is port a source,  i.e. does corresponding vertex receive more than 0"
is_src(port::Port, arr::CompArrow) = lg_to_p(is_src, port, arr)

"Vector of all neighbors of `port`"
neighbors(port::Port, arr::CompArrow)::Vector{Port} = v_to_p(LG.neighbors, port, arr)

"Vector of ports which `port` receives from"
in_neighbors(port::Port, arr::CompArrow)::Vector{Port} = v_to_p(LG.in_neighbors, port, arr)

"Vector of ports which `port` projects to"
out_neighbors(port::Port, arr::CompArrow)::Vector{Port} = v_to_p(LG.out_neighbors, port, arr)

"Return the number of ports which begin at port p"
out_degree(port::Port, arr::CompArrow)::Integer = lg_to_p(LG.outdegree, port, arr)

"Return the number of ports which end at port p"
in_degree(port::Port, arr::CompArrow)::Integer = lg_to_p(LG.indegree, port, arr)

"Should `port` be a src in context `arr`. Possibly false iff is_wired_ok = false"
function should_src(port::Port, arr::CompArrow)::Bool
  # TODO: Is this check necessary?
  if !(port in sub_ports(arr))
    errmsg = "Port $port not in ports of $(name(arr))"
    println(errmsg)
    throw(DomainError())
  end
  if arr == port.arrow
    is_in_port(port)
  else
    is_out_port(port)
  end
end

"Should `port` be a dest in context `arr`? Maybe false iff is_wired_ok=false"
function should_dest(port::Port, arr::CompArrow)::Bool
  if !(port in sub_ports(arr))
    errmsg = "Port $port not in ports of $(name(arr))"
    println(errmsg)
    throw(DomainError())
  end
  if arr == port.arrow
    is_out_port(port)
  else
    is_in_port(port)
  end
end

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
function connected(port::Port, arr::CompArrow)::Set{Port}
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

"Is `arr` wired up correctly"
function is_wired_ok(arr::CompArrow)::Bool
  for i = 1:LG.nv(arr.edges)
    if should_dest(port_index(arr, i), arr)
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
        $(LG.outdegree(arr.edges, 1)) (should be >= 1)"""
        warn(errmsg)
        return false
      end
    end
  end
  true
end
