module Arrows
using Compat
# using Distributions

import Base: call, convert, union, first, second

include("util.jl")
include("types.jl")
include("primitive.jl")
include("arrowtypes2.jl")
# include("combinators.jl")
# include("call.jl")

end
