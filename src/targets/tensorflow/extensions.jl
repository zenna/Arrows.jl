# TensorFlow.jl extensions
"Number of inputs of an `op`"
num_inputs(op::Operation) = length(tf.get_def(op).input)

"`Tensor`s that are inputs to `op`"
get_inputs(op::Operation) = [tf.get_input(op, i) for i = 1:num_inputs(op)]

"name of type of `op` e.g. `add`"
op_type_name(op::Operation) = tf.get_def(op).op

"name of type of `op` e.g. `Add_1`"
op_node_name(op::Operation) = tf.get_def(op).name

function get_graph(ten::Tensor)
  try
    tf.get(ten.op.graph)
  catch
    println("BAD op is", ten.op.graph)
    rethrow()
  end
end
safe_op_type_name(op::Operation)::Bool = op_type_name(op) != "NoOp"
get_safe_ops(graph::Graph) =
  (op for op in tf.get_operations(graph) if safe_op_type_name(op))

"`Operation`s that take `ten` as input"
function consumers(ten::Tensor, graph::Graph)
  [op for op in get_safe_ops(graph) if ten ∈ get_inputs(op)]
end

# function get_tensor(full_name)
#     name, port = parse_port_name(full_name)
#     get_tensor_by_name("$name:$(port-1)")
# end

function get_tensors(graph::Graph)::Vector{Tensor}
  unique(vcat([get_inputs(op) for op in tf.get_safe_ops(graph)]...))
end

"Tensors which are outputs of `op`"
function get_outputs(op::Operation, graph::Graph)::Vector{Tensor}
  println("OP", op)
  println("Graph", op.graph)
  op = filter(ten->ten.op == op, get_tensors(tf.get(op.graph)))
  sort(op, by=ten->ten.index)
end

function eval_const_tensor(tens::Vector{Tensor})
  # sess = tf.Session()
  # run(sess, tens)
end

# Conversion
"Get the constant output of a const op as value"
function get_const_op_value(const_op::Operation)
  eval_const_tensor(get_outputs(const_op))
end

value_index(ten::Tensor) = ten.value_index
