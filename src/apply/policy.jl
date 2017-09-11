Vertex = Int
# What's wrong?
# - We need to say values connected to source nodes are known
# - We may have to resolve a condition before we can compute anything
# - I think I need to copy known

"Describes execution `Policy` of an `Arrow`: which sub_arrows to execute when"
abstract type Policy end

"Type of node in `Policy`, `compute` = evaluate node, `swtich` branch"
@enum NodeType Branch Compute

"""Deterministic `Policy` where order subarrows are executed is deterministic

A `DetPolicy` has two types of nodes, `Compute` and `Branch` nodes.
- edges denote control flow between computations or branching
- each `Compute` node labeleld with `Value` to compute
- each `Compute` node has one input and one output
- each `Branch` node is labelled with `Port` whose type is Boolean
- each `Branch` has one input and two outputs, `true` and `false` branch
- There's exactly one start node: zero in-edges and one out-edges
- There may be multiple end nodes

A `DetPolicy` defines a deterministic semantics of execution of an arrow.
Deterministic subarrows are evaluated sequentially and that order of evaluation
is determined statically:

```
curr_node = start_node()
until curr_node is end_node:
  if curr_node is branch:
    if curr_node.port is true:
      curr_node = next_node(pol, true_branch)
    else
      curr_node = next_node(pol, false_branch)
    end
  else
    compute(curr_node)
    curr_node = next_node(pol)
  end
end
```
"""
mutable struct DetPolicy <: Policy
  edges::LG.DiGraph
  node_type_labels::Vector{NodeType}
  node_port_labels::Vector{Union{SubPort, Value}}
  curr_node::Vertex
  function DetPolicy()
    new(LG.DiGraph(), [], [], 0)
  end
end

"Composite Arrow which this is a policy for"
arrow(pol::DetPolicy) = parent(first(pol.node_port_labels))
isfresh(pol::DetPolicy) = pol.curr_node == 0

"Add a `Compute` node to `pol`"
function add_compute_node!(pol::DetPolicy, value::Value)::Vertex
  v = LG.add_vertex!(pol.edges)
  push!(pol.node_type_labels, Compute)
  push!(pol.node_port_labels, value)
  LG.nv(pol.edges)
end

"Add a `Branch` node to a `pol`"
function add_branch_node!(pol::DetPolicy, subport::SubPort)::Vertex
  v = LG.add_vertex!(pol.edges)
  push!(pol.node_type_labels, Branch)
  push!(pol.node_port_labels, subport)
  LG.nv(pol.edges)
end

"Link node `src` to `dst`"
function link_nodes!(pol::DetPolicy, src::Vertex, dst::Vertex)
  LG.add_edge!(pol.edges, src, dst)
end

"Link node `src` to `dst`"
link_nodes!(pol::DetPolicy, dst::Vertex) = link_nodes!(pol, pol.curr_node, dst)

"Update current node of `pol to `curr``"
update_current!(pol::DetPolicy, curr::Vertex) = pol.curr_node = curr

"Compile `arr` into a `Policy`"
function DetPolicy(known::Values, targets::Values)
  pol = DetPolicy() # new empty policy
  cond_map = CondMap()
  extend_policy!(pol, known, targets, cond_map)
end

"Create `DetPolicy` from `arr` assuming we want all outputs and know all inputs"
function DetPolicy(arr::CompArrow)
  known = in_values(arr)
  targets = out_values(arr)
  DetPolicy(known, targets)
end

"If we know `know`, what other values must be know"
function known_values_if_know(know::Value)::Values
  # Assume we know one output value we know them all
  out_values(src_sub_arrow(know))
end

# "is `value` a switch predicate (i.e. input to at least one i of ite cond)"
# function switch_predicate(value::Value)::Bool
# end
#
# function uncertain_switch(value::Value, cond_map::CondMap)::Bool
#   switch_predicate(value) && value ∉ keys(cond_map)
# end

# FIXME, fix maprecur so can add return typep to this of ::Vector{<:Policy}
"Recursively get all the policies of `carr`"
policies(carr::CompArrow) = maprecur(DetPolicy, carr)

"Extend the policy by adding either `Compute` or `Branch` node"
function extend_policy!(pol::Policy, known::Values,
                        targets::Values, cond_map::CondMap)::Policy
  can_need = can_need_values(known, targets, cond_map)
  all_known = all(value ∈ known for value in targets)
  # conditionals = (value for value in known if uncertain_switch(value, cond_map))
  #
  # # Invariants
  @assert isempty(can_need) == all_known "Known: $known \n can_need: $can_need"# if targets is known, nothing to do!
  if !isempty(can_need)
    next_value = first(can_need)
    # Add node to graph, make it the current node, label it with next_node
    # and update known
    curr = add_compute_node!(pol, next_value)
    if !isfresh(pol)
      link_nodes!(pol, curr)
    end
    update_current!(pol, curr)
    known = known_values_if_know(next_value) ∪ known
    extend_policy!(pol, known, targets, cond_map)
  end
  # if isempty(can_need)
  #   alt_port = first((k for (k, v) in cond_map if v))
  #
  #   add_branch_node!(pol, alt_port)
  #   link_nodes!(pol, curr, pg)
  #   curr = pg
  #
  #   # consider the case when it is true
  #   cond_map[alt_port] = true
  #   push!(known, alt_port)
  #   extend_policy!(pol, known, cond_map)
  #
  #   # Consider the case when it is false
  #   cond_map[alt_port] = true
  #   push!(known, alt_port)
  #   extend_policy!(pol, known, cond_map)
  # else
  #
  # end
  pol
end

function is_compute_node(pol::DetPolicy, node::Vertex)::Bool
  pol.node_type_labels[node] == Compute
end

function is_branch_node(pol::DetPolicy, node::Vertex)::Bool
  pol.node_type_labels[node] == Branch
end

"Is `pol` well formed"
function is_valid(pol::DetPolicy)::Bool
  s = start_node(pol) = 1

  function correct_branching(node)::Bool
    if is_compute_node(pol, node)
      println(node, "  !!  ", LG.outdegree(pol.edges, node))
      LG.outdegree(pol.edges, node) ∈ [1, 0]
    else
      @assert is_branch_node(pol, node)
      LG.outdegree(pol.edges, node) == 2
    end
  end

  # All nodes should have correct branch
  if !all(correct_branching(node) for node in LG.vertices(pol.edges))
    println("Incorrect branching")
    return false
  end

  if !LG.is_weakly_connected(pol.edges)
    println("Not connected!")
    return false
  end

  if LG.indegree(pol.edges, start_node(pol)) != 0
    println("Start node broken!")
    return false
  end
  return true
end

start_node(det::DetPolicy) = 1
end_node(det::DetPolicy, curr::Vertex)::Bool =
  LG.outdegree(det.edges, curr) == 0
curr_value(pol::DetPolicy, node::Vertex)::Value = pol.node_port_labels[node]
function next_node(pol::DetPolicy, node::Vertex)
  # warn("will break for branching")
  node + 1 #FIXME: WILL BREAK FOR
end

"Evaluate an arrow using a `pol` on `args`: arrow(pol)(args...)"
function interpret(pol::DetPolicy, args...)
  arr = arrow(pol)
  if length(args) != num_in_ports(arr)
    throw(DomainError())
  end
  # Map frin `Value` to arguments, init with inputs
  vals = Dict{Value, Any}(zip(in_values_vec(sub_arrow(arr)), args))
  curr_node = start_node(pol)

  # Until we reach the end node ...
  while true
    # 1. Find out which subarrow we need to compute to compute curr_node
    val = curr_value(pol, curr_node)
    sarr = src_sub_arrow(val)

    # FIXME: dont repeat execution of sarr if we already have `val`

    # 2. Find both input and output values for this subarrow
    invals = in_values_vec(sarr)
    outvals = out_values_vec(sarr)

    # 3. Extract actual values for these `Values` and execute subarrow on this
    valvals = [vals[val] for val in invals]
    ops = interpret(deref(sarr), valvals...)

    # 4. Update all outputs of subarrow with value
    for (i, op) in enumerate(ops)
      vals[outvals[i]] = ops[i]
    end

    # Stop if we reach the end node
    if end_node(pol, curr_node)
      break
    else
      curr_node = next_node(pol, curr_node)
    end
  end
  sarr = sub_arrow(arr)
  outvals = out_values_vec(sarr)
  [vals[val] for val in outvals]
end

"Evaluate an arrow using a `pol` on `args`: arrow(pol)(args...)"
function pinterpret(pol::DetPolicy, f, args...)
  arr = arrow(pol)
  if length(args) != num_in_ports(arr)
    @show length(args), num_in_ports(arr)
    throw(DomainError())
  end
  # Map frin `Value` to arguments, init with inputs
  vals = Dict{Value, Any}(zip(in_values_vec(sub_arrow(arr)), args))
  curr_node = start_node(pol)

  # Until we reach the end node ...
  while true
    # 1. Find out which subarrow we need to compute to compute curr_node
    val = curr_value(pol, curr_node)
    sarr = src_sub_arrow(val)

    # FIXME: dont repeat execution of sarr if we already have `val`

    # 2. Find both input and output values for this subarrow
    invals = in_values_vec(sarr)
    outvals = out_values_vec(sarr)

    # 3. Extract actual values for these `Values` and execute subarrow on this
    valvals = [vals[val] for val in invals]
    ops = f(sarr, valvals...)

    # 4. Update all outputs of subarrow with value
    for (i, op) in enumerate(ops)
      vals[outvals[i]] = ops[i]
    end

    # Stop if we reach the end node
    if end_node(pol, curr_node)
      break
    else
      curr_node = next_node(pol, curr_node)
    end
  end
  sarr = sub_arrow(arr)
  outvals = out_values_vec(sarr)
  [vals[val] for val in outvals]
end

expr(arr::SourceArrow, args...) = arr.value
expr(arr::Arrow, args...) = Expr(:call, name(arr), args...)

"Convert a policy into a julia program"
function pol_to_julia(pol::Policy)
  carr = arrow(pol)
  argnames = map(name, in_values_vec(sub_arrow(carr)))
  coutnames = map(name, out_values_vec(sub_arrow(carr)))
  assigns = Vector{Expr}()
  ouputs = Vector{Expr}()
  function f(sarr::SubArrow, args...)
    arr = deref(sarr)
    outnames = map(name, tuple(out_values_vec(sarr)...))
    lhs = Expr(:tuple, outnames...)
    rhs = expr(arr, args...)
    push!(assigns, Expr(:(=), lhs, rhs))
    outnames
  end
  pinterpret(pol, f, argnames...)

  #
  retargs = Expr(:tuple, coutnames...)
  ret = Expr(:return, retargs)
  # Function head
  funcname = name(carr)
  funchead = Expr(:call, funcname, argnames...)
  # function block
  funcblock = Expr(:block, assigns..., ret)
  # All together
  Expr(:function, funchead, funcblock)
end
