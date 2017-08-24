# import Arrows
using NamedTuples
import TensorFlow
const tf = TensorFlow
using PyCall

function julia_test_graph()
  graph = tf.Graph()
  sess = TensorFlow.Session(graph)
  TensorFlow.set_def_graph(graph)
  sess = TensorFlow.Session()
  x = TensorFlow.constant(Float64[1,2], name="x")
  y = TensorFlow.Variable(Float64[3,4], name="y")
  z = TensorFlow.placeholder(Float64, name="z")

  w = exp(x + z + -y)
  ops = tf.get_operations(graph)
  println("OPS", map(op->tf.get_def(op).op, collect(ops)))
  @NT(graph = graph, inputs = [z], outputs = [w], sess = sess)
end

"Create and save a test meta_graph"
function save_test_meta_graph()
  @pyimport tensorflow as tf
  @pyimport tensorflow.python.training.saver as saver
  g = tf.Graph()
  @pywith g[:as_default]() begin
    x = tf.placeholder(dtype="float32", shape=())
    y = tf.placeholder(dtype="float32", shape=())
    z = x * y + x
    fname = "tmp.meta"
    saver.export_meta_graph(filename=fname)
  end
end

function test_convert()
  res = julia_test_graph()
  sess = TensorFlow.Session(res.graph)
  tf.run(sess, TensorFlow.global_variables_initializer())
  Arrows.graph_to_arrow(:xyexp, res.inputs, res.outputs, res.graph)
end

res = julia_test_graph()
test_convert()
tf.get_input
(o->get(o.graph)).(collect(get_safe_ops(res.graph)))
(o->op_node_name(o)).(collect(get_safe_ops(res.graph)))

z = res.outputs[1]
opa = get_inputs(z.op)[1].op
opg = tf.get_def(opa)
opa
get_inputs(opa)

fieldnames(opg)
opg.name
tf.get_tensor_by_name(res.graph, "Add_2").op.graph

# tf.get_def(ops[4])
# get_inputs.(ops[1:9])
# ops
# unique(collect(tf.get_operations(res.graph)))
# g = julia_test_graph()
#
# res = julia_test_graph()
# aname = :xyexp
# inp_tens = res.inputs
# out_tens = res.outputs
#
# op_to_arrow = Dict{Operation, Arrow}()
# seen_tens = Set{Tensor}()
# I, O = length(inp_tens), length(out_tens)
# c = CompArrow{I, O}(aname)
#
# # Make an in_port for every input ten
# ten_in_port = Dict{Port, Tensor}(zip(in_ports(c), inp_tens))
# # set_port_shape(in_port, const_to_tuple(ten.get_shape().as_list()))
#
# # Make an out_port for every output ten
# for (id, ten) in enumerate(out_tens)
#   arrow = arrow_from_op(c, ten.op, op_to_arrow)
#   left = out_port(arrow, ten.value_index)
#   link_ports!(c, left, out_port(c, id))
# end
#
# xy
#
# to_see_tens = copy(out_tens)
# ten = pop!(to_see_tens)
# push!(seen_tens, ten)


# graph = tf.Graph()
# TensorFlow.set_def_graph(graph)
# sess = TensorFlow.Session()
# x = TensorFlow.constant(Float64[1,2])
# y = TensorFlow.Variable(Float64[3,4])
# z = TensorFlow.placeholder(Float64)
# xy = x + y
# z = xy + x
# xy.op
