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

function test_decode()
  x = pytf.placeholder("float32")
  y = x + x
  input_tensors = PyTensor[x]
  output_tensors = PyTensor[y]
  graph::PyGraph = pytf.get_default_graph()
  arr = graph_to_arrow(:test, input_tensors, output_tensors, graph)
  @test is_valid(arr)
end

function test_convert()
  res = julia_test_graph()
  sess = TensorFlow.Session(res.graph)
  tf.run(sess, TensorFlow.global_variables_initializer())
  Arrows.graph_to_arrow(:xyexp, res.inputs, res.outputs, res.graph)
end

test_decode()
