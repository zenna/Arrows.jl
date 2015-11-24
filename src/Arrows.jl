module Arrows
using Compat
using PyCall
using ZenUtils
using SMTBase
using Z3
import SMTBase: Variable, ParameterExpr, Parameter, ConstraintSet, ParameterSet,
                ConstantVar, nonnegparam, IndexedParameter, shape, VarArray, ConstrainedParameter,
                TransformedParameter, parameters

# using Distributions

import Base.Collections: PriorityQueue, dequeue!, peek

import Base: call, convert, union, first, ndims, print, println, string, show,
  showcompact, >>>, length, isequal, eltype

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
  over,
  under,
  lift,
  multiplex,
  stack,
  encapsulate,
  inswitch,
  init,

  _,

  name,
  conv2dfunc,
  addfunc,
  relu1dfunc,

  inppintype,
  outpintype,

  typ,
  dimtyp,
  @shape,
  @arrtype,
  @intparams,
  partial,
  typeparams

include("util.jl")
include("types.jl")
include("arrow.jl")
include("combinators.jl")
include("compile.jl")
include("call.jl")

include("types/typecheck.jl")
include("library.jl")

# include("smt_solvers/z3interface.jl")
include("compilation_targets/theano.jl")
# include("compilation_targets/stan.jl")

# using Arrows.Library
end
