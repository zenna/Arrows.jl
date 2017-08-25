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
include("encode.jl")
# include("decode.jl")

end
