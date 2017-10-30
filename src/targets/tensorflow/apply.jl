using Base.Test
using TensorFlow
const tf = TensorFlow

"Evaluate a graph"
function tfapply(intens, outtens, args, sess=tf.Session())
  TensorFlow.run(sess, TensorFlow.global_variables_initializer())
  run(sess, outtens, Dict(zip(intens, args)))
end

function test_tf_apply()
  sess = TensorFlow.Session()
  x = TensorFlow.constant(Float64[1,2])
  y = TensorFlow.Variable(Float64[3,4])
  z = TensorFlow.placeholder(Float64)
  w = exp(x + z + -y)
  wval = tfapply([z], w, [1.0])
  @test exp([1,2] .+ 1.0 + -[3,4]) == wval
end
