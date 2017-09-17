

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
    outvals = out_values(sarr)

    # 3. Extract actual values for these `ValueSet` and execute subarrow on this
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
  outvals = out_values(sarr)
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
    outvals = out_values(sarr)

    # 3. Extract actual values for these `ValueSet` and execute subarrow on this
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
  outvals = out_values(sarr)
  [vals[val] for val in outvals]
end

"Convert a policy into a julia program"
function pol_to_julia(pol::Policy)
  carr = arrow(pol)
  argnames = map(name, in_values_vec(sub_arrow(carr)))
  coutnames = map(name, out_values(sub_arrow(carr)))
  assigns = Vector{Expr}()
  ouputs = Vector{Expr}()
  function f(sarr::SubArrow, args...)
    arr = deref(sarr)
    outnames = map(name, tuple(out_values(sarr)...))
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
