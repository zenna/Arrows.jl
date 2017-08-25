"Conversion to and from tensorflow graphs"
module TensorFlowTarget
using ..Arrows
import ..Arrows: Arrow
using PyCall
import TensorFlow
const tf = TensorFlow

import TensorFlow: Operation, Graph, Tensor, Session, get_op
import Base.convert

include("extensions.jl")
include("python.jl")
include("types.jl")
include("to_arrow.jl")
# include("decode.jl")

export graph_to_arrow,
       PyTensor,
       PyOperation,
       PyGraph

end
