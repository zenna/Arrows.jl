module Arrows
using Compat
using PyCall
# using Distributions

import Base: call, convert, union, first

include("util.jl")
include("types.jl")
include("primitive.jl")
include("arrowtypes.jl")
include("combinators.jl")
include("call.jl")
include("compile/stan.jl")
include("primfuncs.jl")
include("primarrows.jl")


export
  compose,
  first,
  lift,
  multiplex,
  name

end
