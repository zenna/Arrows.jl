module Arrows
using Compat
using PyCall
# using Distributions

import Base.Collections: PriorityQueue, dequeue!, peek

import Base: call, convert, union, first, ndims, print, println, string, show,
  showcompact, >>>, length

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
  outpintype,

  typ,
  @shape,
  @arrtype,
  @intparams,
  fix

include("util.jl")
include("kinds.jl")
include("maketypes.jl")
include("arrowtypes.jl")
include("combinators.jl")
include("compile.jl")
include("call.jl")

include("library.jl")

include("compilation_targets/stan.jl")
include("compilation_targets/theano.jl")

# using Arrows.Library
end
