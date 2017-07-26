import LightGraphs: Graph, add_edge!, add_vertex!, connected_components,
  weakly_connected_components

"Does a vector of port attributes have I inports and O outports?"
function is_valid_port_attrs(port_attrs::Vector{PortAttrs}, I::Integer, O::Integer)::Bool
  ni = 0
  no = 0
  for port_attr in port_attrs
    if is_in_port(port_attr)
      ni += 1
    elseif is_out_port(port_attr)
      no += 1
    end
  end
  ni == I && no == O
end

"Directed Composite Arrow"
type CompArrow{I, O} <: Arrow{I, O}
  name::Symbol                  # name of CompArrow
  id::Symbol                    # Unique id
  edges::LightGraphs.DiGraph    # Graph over port indices - each port unique id
  port_map::Vector{Port}        # port_map[i] is `Port` with index i in `edges`
  port_attrs::Vector{PortAttrs} # Mapping from border port to attributes


  function CompArrow{I, O}(name::Symbol, port_attrs::Vector{PortAttrs}) where{I, O}
    if !is_valid_port_attrs(port_attrs, I, O)
      throw(DomainError())
    end
    c = new()
    nports = I + O
    g = LightGraphs.DiGraph(nports)
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

"Return all the sub_arrows of `arr` excluding arr itself"
function sub_arrows(arr::CompArrow)::Vector{Arrow}
  unique([port.arrow for port in arr.port_map if port.arrow != arr])
end

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

# Graph traversal
"is vertex `v` a destination, i.e. does it project more than 0 edges"
is_dest(g::LightGraphs.DiGraph, v::Integer) = LightGraphs.indegree(g, v) > 0

"is vertex `v` a source, i.e. does it receive more than 0 edges"
is_src(g::LightGraphs.DiGraph, v::Integer) = LightGraphs.outdegree(g, v) > 0

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
neighbors(port::Port, arr::CompArrow)::Vector{Port} = v_to_p(LightGraphs.neighbors, port, arr)

"Vector of ports which `port` projects to"
in_neighbors(port::Port, arr::CompArrow)::Vector{Port} = v_to_p(LightGraphs.in_neighbors, port, arr)

"Vector of ports which `port` projects to"
out_neighbors(port::Port, arr::CompArrow)::Vector{Port} = v_to_p(LightGraphs.out_neighbors, port, arr)

"Return the number of ports which begin at port p"
out_degree(port::Port, arr::CompArrow)::Integer = lg_to_p(LightGraphs.outdegree, port, arr)

"Return the number of ports which end at port p"
in_degree(port::Port, arr::CompArrow)::Integer = lg_to_p(LightGraphs.indegree, port, arr)

"`port` is a source wrt to context `arr` if"
function should_src{A<:CompArrow}(port::Port{A}, arr::CompArrow)::Bool
  # TODO: Is this check necessary?
  if !(port in ports(arr))
    "The port should be "
    throw(DomainError())
  end
  if arr == port.arrow
    is_in_port(port)
  else
    is_out_port(port)
  end
end

function should_dest{A<:CompArrow}(port::Port{A}, arr::CompArrow)::Bool
  if !(port in ports(arr))
    "The port should be "
    throw(DomainError())
  end
  if arr == port.arrow
    is_out_port(port)
  else
    is_in_port(port)
  end
end

should_src{A<:CompArrow}(port::Port{A}) = is_src(port, port.arrow)

is_dest{A<:CompArrow}(port::Port{A}) = is_dest(port, port.arrow)


# Primitive
is_src{A<:PrimArrow}(port::Port{A}, arr::CompArrow)::Bool = is_out_port(port)

is_dest{A<:PrimArrow}(port::Port{A}, arr::CompArrow)::Bool = is_in_port(port)

"Is `arr` wired up correctly"
function is_wired_ok(arr::CompArrow)::Bool
  for i = 1:LightGraphs.nv(arr.edges)
    if should_dest(port_index(arr, i), arr)
      # If it should be a desination
      if !(LightGraphs.indegree(arr.edges, i) == 1 &&
           LightGraphs.outdegree(arr.edges, i) == 0)
      # TODO: replace error with lens
        errmsg = """vertex $i Port $(port_index(arr, i)) should be a dest but
                    indeg is $(LightGraphs.indegree(arr.edges, i)) (notbe 1)
                    outdeg is $(LightGraphs.outdegree(arr.edges, i) == 0)) (not 0)
                  """
        warn(errmsg)
        return false
      end
    end
    if should_src(port_index(arr, i), arr)
      # if it should be a source
      if !(LightGraphs.outdegree(arr.edges, i) > 0 || LightGraphs.indegree(arr.edges) == 1)
        errmsg = """vertex $i Port $(port_index(arr, i)) is source but out degree is
        $(LightGraphs.outdegree(arr.edges, 1)) (should be >= 1)"""
        warn(errmsg)
        return false
      end
    end
  end
  true
end

# FIXME: This can be done much more quickly with connece components on LG
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

"""Partition the ports into weakly connected equivalence classes"""
function weakly_connected_components(arr::CompArrow)::Vector{Vector{Port}}
  cc = weakly_connected_components(arr.edges)
  pi = i->port_index(arr, i)
  map(component->pi.(component), cc)
end
