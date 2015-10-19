module Arrows
using Compat
using PyCall
# using Distributions


import Base: call, convert, union, first, ndims, print, println, string, show,
  showcompact, >>>

export
  compose,
  first,
  over,
  lift,
  multiplex,
  name,
  conv2dfunc,
  addfunc,
  relu1dfunc

include("util.jl")
include("types.jl")
include("primitive.jl")
include("arrowtypes.jl")
include("combinators.jl")
include("compile.jl")
include("compilation_targets/stan.jl")
include("compilation_targets/theano.jl")
include("primfuncs.jl")
include("primarrows.jl")

include("library.jl")




end
