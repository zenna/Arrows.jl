"Conversion to and from tensorflow graphs"
module TensorFlowTarget
using ..Arrows
using PyCall
import TensorFlow
const tf = TensorFlow

import TensorFlow: Operation, Graph, Tensor, Session
import Base.convert

include("extensions.jl")
include("encode.jl")
include("decode.jl")

end
