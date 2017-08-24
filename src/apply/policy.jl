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
struct DetPolicy <: Policy
  edges::LG.DiGraph
  node_type_laberrowsls::Vector{NodeType}
  node_port_labels::Vector{Union{Port, Value}}
end

function DetPolicy()
  DetPolicy(LG.DiGraph(), [], [])
end

"Is the policy structured correctly?"
function is_valid(pol::DetPolicy)::Bool
  # one_start_node = ...
  # FIXME:
  true
end

"Add a `Compute` node to `pol`"
function add_node!(pol::DetPolicy, port::Value, ::Type{Compute})
  LG.add_vertex(pol.edges)
  push!(pol.node_labels, Compute)
end

"Add a `Branch` node to a `pol`"
function add_node!(pol::DetPolicy, port::Port, ::Type{Branch})
  add_vertex(pol.edges)
  push!(pol.node_labels, Branch)
end

"Link node `src` to `dest`"
function link_nodes!(pol::DetPolicy, src, dest)
  LG.add_edge!(pol.edges, src, dest)
end

"Compile `arr` into a `Policy`"
function DetPolicy(arr::CompArrow, known::Values, targets::Values)
  pol = DetPolicy() # new empty policy
  cond_map = CondMap()
  extend_policy!(arr, pol, known, targets, cond_map)
end

"Create `DetPolicy` from `arr` assuming we want outputs and know inputs"
function DetPolicy(arr::CompArrow)
  known = in_values(arr)
  targets = out_values(arr)
  DetPolicy(arr, known, targets)
end

"Extend the policy by adding either compute or branch node"
function extend_policy!(arr::CompArrow, pol::Policy, known::Values,
                        targets::Values, cond_map::CondMap)
  can_need = can_need_ports(arr, known, targets, cond_map)
  if isempty(can_need)
    alt_port = first((k for (k, v) in cond_map if v))

    add_branch_node!(pol, alt_port)
    link_nodes!(pol, curr, pg)
    curr = pg

    # consider the case when it is true
    cond_map[alt_port] = true
    push!(known, alt_port)
    extend_policy!(arr, pol, known, cond_map)

    # Consider the case when it is false
    cond_map[alt_port] = true
    push!(known, alt_port)
    extend_policy!(arr, pol, known, cond_map)
  else
    pg = first(can_need)
    add_compute_node!(pol, pg)
    link_nodes!(pol, curr, pg)
    # update known
    curr = pg
  end
  pol
end
