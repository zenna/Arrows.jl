module Arrows
using Compat
using PyCall
# using Distributions

import Base.Collections: PriorityQueue, dequeue!, peek

import Base: call, convert, union, first, ndims, print, println, string, show,
  showcompact, >>>

export
  # Combinators
  compose,
  first,
  over,
  lift,
  multiplex,
  stack,
  
  name,
  conv2dfunc,
  addfunc,
  relu1dfunc,

  inppintype,
  outpintype

include("util.jl")
include("kinds.jl")
include("arrowtypes.jl")
include("combinators.jl")
include("compile.jl")
include("call.jl")

include("library.jl")

include("compilation_targets/stan.jl")
include("compilation_targets/theano.jl")


end
