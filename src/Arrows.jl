module Arrows
using ZenUtils
# using SMTBase
# using Z3
# import SMTBase: Variable, ParameterExpr, Parameter, ConstraintSet, ParameterSet,
#                 ConstantVar, nonnegparam, IndexedParameter, shape, VarArray, ConstrainedParameter,
#                 TransformedParameter, parameters, FixedLenVarArray

# using Distributions
import LightGraphs; const LG = LightGraphs
import Base.Collections: PriorityQueue, dequeue!, peek

import Base: convert, union, first, ndims, print, println, string, show,
  showcompact, >>>, length, isequal, eltype, hash, isequal, copy

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
              !,
              in,
              parent

export
  compose,
  name,

  Arrow,
  Port,

  CompArrow,
  link_ports!,
  add_sub_arr!,
  in_port,
  in_ports,
  out_port,
  out_ports,
  port,
  ports,
  propagate,
  is_wired_ok,

  AddArrow,
  MulArrow,
  SourceArrow,
  CondArrow,
  EqualArrow,
  SubtractArrow,
  DivArrow,
  IdentityArrow,
  ExpArrow,
  NegArrow,
  GatherNdArrow

include("util/misc.jl")
# include("types.jl")

include("arrows/arrow.jl")
include("arrows/port.jl")
include("arrows/primarrow.jl")
include("arrows/comparrow.jl")
include("arrows/value.jl")
include("arrows/trace.jl")
include("arrows/port_arith.jl")

# Library
include("library/common.jl")
include("library/arithmetic.jl")
include("library/control.jl")
include("library/source.jl")
include("library/array.jl")


include("combinators/compose.jl")

include("apply/preddisp.jl")
include("apply/propagate.jl")
# include("apply/interpret.jl")
include("apply/depend.jl")
include("apply/policy.jl")

include("transform/generic.jl")
include("transform/invert.jl")

# include("library.jl")

include("targets/julia/julia.jl")
include("targets/tensorflow/tensorflow.jl") # TODO Make optional

include("../test/TestArrows.jl")

# include("smt_solvers/z3interface.jl")
end
