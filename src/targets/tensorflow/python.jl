import Base: convert, hash, isequal, ==
@pyimport tensorflow as pytf

"Light wrapper around Tensor"
struct PyTensor
  ten::PyObject
end

==(x::PyTensor, y::PyTensor) = x.ten == y.ten
isequal(x::PyTensor, y::PyTensor) = x.ten == y.ten
hash(x::PyTensor) = hash(x.ten)

function convert(::Type{PyTensor}, ten::PyObject)
  PyTensor(ten)
end

"Light wrapper around Operation"
struct PyOperation
  op::PyObject
end

==(x::PyOperation, y::PyOperation) = x.op == y.op
isequal(x::PyOperation, y::PyOperation) = x.op == y.op
hash(x::PyOperation) = hash(x.op)

function convert(::Type{PyOperation}, op::PyObject)
  PyOperation(op)
end

"Light wrapper around Graph"
struct PyGraph
  graph::PyObject
end

==(x::PyGraph, y::PyGraph) = x.graph == y.graph
isequal(x::PyGraph, y::PyGraph) = x.graph == y.graph
hash(x::PyGraph) = hash(x.graph)

function convert(::Type{PyGraph}, ten::PyObject)
  PyGraph(ten)
end

get_inputs(op::PyOperation)::Vector{PyTensor} = op.op[:_inputs]
num_inputs(op::PyOperation) = length(get_inputs(op))
get_outputs(op::PyOperation)::Vector{PyTensor} = op.op[:_inputs]
num_outputs(op::PyOperation) = length(get_outputs(op))

op_type_name(op::PyOperation) = op.op[:type]
op_node_name(op::PyOperation) = op.op[:name]
get_graph(op::PyOperation)::PyGraph = op.op[:graph]
consumers(ten::PyTensor)::Vector{PyOperation} = ten.ten[:consumers]()

get_op(ten::PyTensor)::PyOperation = ten.ten[:op]
value_index(ten::PyTensor) = ten.ten[:value_index]

function get_const_op_value(op::PyOperation)
  graph = get_graph(op)
  sess = pytf.Session(graph=graph.graph)
  value = op.op[:outputs][1][:eval](session=sess)
  sess[:close]()
  value
end
