"Conversion to and from tensorflow graphs"
module TensorFlowTarget
import ..Arrows: Arrow, Target, CompArrow
using Arrows
using PyCall
using NamedTuples
import TensorFlow
const tf = TensorFlow

import TensorFlow: Operation, Graph, Tensor, Session, get_op
import Base: convert, hash, isequal, ==

# #
include("extensions.jl")
# include("python.jl")
# include("types.jl")
# include("to_arrow.jl")
include("decode.jl")
# #
"Tensorflow target for dispatch"
struct TFTarget <: Target end
#
"Compiles `arr` into `Expr` tensorflow program"
compile(arr::Arrow, target::TFTarget) = Graph(arr)
# #
# #
# export graph_to_arrow,
#        PyTensor,
#        PyOperation,
#        PyGraph

end
