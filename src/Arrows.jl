module Arrows
using Compat
using PyCall
# using Distributions

import Base.Collections: PriorityQueue, dequeue!, peek

import Base: call, convert, union, first, ndims, print, println, string, show,
  showcompact, >>>, length, isequal

import Base:  ^,
              +,
              -,
              *,
              /,
              >,
              >=,
              <=,
              <,
              ==,
              !=,
              |,
              &,
              !

export
  # Combinators
  compose,
  first,
  over,
  under,
  lift,
  multiplex,
  stack,
  encapsulate,

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
include("types.jl")
include("arrow.jl")
include("combinators.jl")
include("compile.jl")
include("call.jl")

include("types/typecheck.jl")
include("library.jl")
include("smt_solvers/z3interface.jl")

# include("compilation_targets/theano.jl")
# include("compilation_targets/stan.jl")

# using Arrows.Library
end
