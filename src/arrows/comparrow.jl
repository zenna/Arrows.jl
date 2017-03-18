## Composite Arrows
## ================
import LightGraphs: Graph, add_edge!, add_vertex!, connected_components, weakly_connected_components

"Directed Composite Arrow"
type CompArrow{I, O} <: Arrow{I, O}
  name::Symbol                  # name of CompArrow
  id::Symbol                    # Unique id
  edges::LightGraphs.DiGraph    # Each port has a unique index
  port_map::Vector{Port}        # Mapping from port indices in edges to Port
  port_attrs::Vector{PortAttrs} # Mapping from border port to attributes
  parent::Nullable{CompArrow}   # CompArrow which this arrow is subarrow of

  "Constructs CompArrow with Any"
  function CompArrow(name::Symbol)
    c = new()
    nports = I + O
    g = LightGraphs.DiGraph(nports)
    port_map = [Port(c, i) for i=1:nports]
    in_port_attrs = [PortAttrs(true, Symbol(:inp_, i), Any) for i = 1:I]
    out_port_attrs = [PortAttrs(false, Symbol(:out_, i), Any) for i = 1:O]
    port_attrs = vcat(in_port_attrs, out_port_attrs)
    c.name = name
    c.id = gen_id()
    c.port_map = port_map
    c.edges = g
    c.port_attrs = port_attrs
    c.parent = Nullable{CompArrow}()
    c
  end
end

"Return all the sub_arrows of `arr` excluding arr itself"
function sub_arrows(arr::CompArrow)::Vector{Arrow}
  unique([port.arrow for port in arr.port_map if port.arrow != arr])
end

"Return all the sub_arrows of `arr` including arr itself"
function all_sub_arrows(arr::CompArrow)::Vector{Arrow}
  unique([port.arrow for port in arr.port_map])
end

"Does the arrow have a parent? (is it within a composition)?"
is_parentless(arr::Arrow)::Bool = isnull(arr.parent)

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

function set_parent!(arr::Arrow, c_arr::CompArrow)::Arrow
  if arr == c_arr || !is_parentless(arr)
    throw(DomainError())
  else
    arr.parent = c_arr
  end
end

"Add a sub_arrow `arr` to composition `c_arr`"
function add_sub_arr!(arr::Arrow, c_arr::CompArrow)::Arrow
  if arr in c_arr
    throw(DomainError())
  else
    arr2 = set_parent!(arr, c_arr)
    for port in ports(arr2)
      add_port!(c_arr, port)
    end
    arr2
  end
end

"Add an edge in CompArrow from port `l` to port `r`"
function link_ports!(c::CompArrow, l::Port, r::Port)
  l_idx = port_index(c, l)
  r_idx = port_index(c, r)
  add_edge!(c.edges, l_idx, r_idx)
end

# Graph traversal
"is vertex `v` a destination"
is_dest(g::LightGraphs.DiGraph, v::Integer) = LightGraphs.indegree(g, v) > 0

"is vertex `v` a source"
is_src(g::LightGraphs.DiGraph, v::Integer) = LightGraphs.outdegree(g, v) > 0

#FIXME: Turn this into a macro for type stability
"Helper function to translate LightGraph functions to Port functions"
function lg_to_p(f::Function, port::Port, arr::CompArrow)
  f(arr.edges, port_index(arr, port))
end

function v_to_p(f::Function, port::Port, arr::Arrow)
  map(i->port_index(arr, i), lg_to_p(f, port, arr))
end

"Is port a destination"
is_dest(port::Port, arr::CompArrow) = lg_to_p(is_dest, port, arr)

"Is port a source"
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

is_src{A<:CompArrow}(port::Port{A}, arr::CompArrow)::Bool = is_in_port(port)

is_dest{A<:CompArrow}(port::Port{A}, arr::CompArrow)::Bool = is_out_port(port)

is_src{A<:CompArrow}(port::Port{A}) = is_src(port, port.arrow)

is_dest{A<:CompArrow}(port::Port{A}) = is_dest(port, port.arrow)

neighbors{A<:CompArrow}(port::Port{A}) = neighbors(port, port.arrow)

in_neighbors{A<:CompArrow}(port::Port{A}) = in_neighbors(port, port.arrow)

out_neighbors{A<:CompArrow}(port::Port{A}) = out_neighbors(port, port.arrow)

out_degree{A<:CompArrow}(port::Port{A}) = out_degree(port, port.arrow)

in_degree{A<:CompArrow}(port::Port{A}) = in_degree(port, port.arrow)

# Primitive
is_src{A<:PrimArrow}(port::Port{A}, arr::CompArrow)::Bool = is_out_port(port)

is_dest{A<:PrimArrow}(port::Port{A}, arr::CompArrow)::Bool = is_in_port(port)

is_src{A<:PrimArrow}(port::Port{A}) = is_src(port, parent(port.arrow))

is_dest{A<:PrimArrow}(port::Port{A}) = is_dest(port, parent(port.arrow))

neighbors{A<:PrimArrow}(port::Port{A}) = neighbors(port, parent(port.arrow))

in_neighbors{A<:PrimArrow}(port::Port{A}) = in_neighbors(port, parent(port.arrow))

out_neighbors{A<:PrimArrow}(port::Port{A}) = out_neighbors(port, parent(port.arrow))

out_degree{A<:PrimArrow}(port::Port{A}) = out_degree(port, parent(port.arrow))

in_degree{A<:PrimArrow}(port::Port{A}) = in_degree(port, parent(port.arrow))

"Is `arr` wired up correctly"
function is_wired_correct(arr::CompArrow)::Bool
  for i = 1:LightGraphs.nv(arr.edges)
    if is_dest(port_index(arr, i)) && LightGraphs.indegree(arr.edges, i) != 1
      return false
    end
    if is_src(port_index(arr, i)) && LightGraphs.outdegree(arr.edges, 1) < 1
      return false
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
