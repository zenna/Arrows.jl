import Base: convert, hash, isequal, ==
using PyCall
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
get_graph(op::PyOperation)::PyGraph = pyop.op[:graph]
consumers(ten::PyTensor)::Vector{PyOperation} = ten.ten[:consumers]()

get_op(ten::PyTensor)::PyOperation = ten.ten[:op]
value_index(ten::PyTensor) = ten.ten[:value_index]

function test_decode()
  x = pytf.placeholder("float32")
  y = x + x
  input_tensors = PyTensor[x]
  output_tensors = PyTensor[y]
  graph::PyGraph = pytf.get_default_graph()
  graph_to_arrow(:test, input_tensors, output_tensors, graph)
end

AbstractTensor = Union{PyTensor, Tensor}
AbstractOperation = Union{PyOperation, Operation}
AbstractGraph = Union{PyGraph, Graph}
AbstractGraph = Union{PyGraph, Graph}
AbstractGraph
