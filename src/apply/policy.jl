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
  node_port_labels::Vector{Union{Port, Value}}
  curr_node::Vertex
  function DetPolicy()
    new(LG.DiGraph(), [], [], 0)
  end
end

isfresh(pol::DetPolicy) = pol.curr_node == 0

"Is the policy structured correctly?"
function is_valid(pol::DetPolicy)::Bool
  # one_start_node = ...
  # FIXME:
  true
end

"Add a `Compute` node to `pol`"
function add_compute_node!(pol::DetPolicy, value::Value)::Vertex
  v = LG.add_vertex!(pol.edges)
  push!(pol.node_type_labels, Compute)
  push!(pol.node_port_labels, value)
  v
end

"Add a `Branch` node to a `pol`"
function add_branch_node!(pol::DetPolicy, subport::SubPort)::Vertex
  v = LG.add_vertex!(pol.edges)
  push!(pol.node_type_labels, Branch)
  push!(pol.node_port_labels, subport)
  v
end

"Link node `src` to `dst`"
function link_nodes!(pol::DetPolicy, src::Vertex, dst::Vertex)
  LG.add_edge!(pol.edges, src, dst)
end

"Link node `src` to `dst`"
link_nodes!(pol::DetPolicy, dst::Vertex) = link_nodes(pol, pol.curr_node, dst)

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
  out_values(src_arrow(know))
end

# "is `value` a switch predicate (i.e. input to at least one i of ite cond)"
# function switch_predicate(value::Value)::Bool
# end
#
# function uncertain_switch(value::Value, cond_map::CondMap)::Bool
#   switch_predicate(value) && value ∉ keys(cond_map)
# end

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
