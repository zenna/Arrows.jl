
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

# DetPolicy Interface #

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

"Is `node` a `Compute` node?"
is_compute_node(pol::DetPolicy, node::Vertex)::Bool =
  pol.node_type_labels[node] == Compute

"is `node` a `Branch node`?"
is_branch_node(pol::DetPolicy, node::Vertex)::Bool =
  pol.node_type_labels[node] == Branch

"Compile `arr` into a `Policy`"
function DetPolicy(known::ValueSet, targets::ValueSet)
  pol = DetPolicy() # new empty policy
  cond_map = CondMap()
  extend_policy!(pol, known, targets, cond_map)
end

"Create `DetPolicy` from `arr` assuming we want all outputs and know all inputs"
function DetPolicy(arr::CompArrow)
  known = in_values(arr)
  targets = out_values(arr)
  DetPolicy(Set(known), Set(targets))
end

"Recursively get all the policies of `carr`"
policies(carr::CompArrow) = maprecur(DetPolicy, carr)

"Extend the policy by adding either `Compute` or `Branch` node"
function extend_policy!(pol::Policy, known::ValueSet,
                        targets::ValueSet, cond_map::CondMap)::Policy
  can_need = can_need_values(known, targets, cond_map)
  all_known = all(value ∈ known for value in targets)
  # conditionals = (value for value in known if uncertain_switch(value, cond_map))
  #
  # # Invariants
  # if targets is known, nothing to do!
  @assert isempty(can_need) == all_known "Known: $known \n can_need: $can_need"
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
  pol
end
