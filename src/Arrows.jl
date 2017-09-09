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
  showcompact, length, isequal, eltype, hash, isequal, copy, ∘

import Base:  ^,
              +,
              -,
              *,
              /,
              >,
              >=,
              <=,
              <,
              !=,
              ==,
              |,
              &,
              !,
              in,
              parent,
              >>,
              <<
export
  compose,
  name,

  Arrow,
  Port,
  SubPort,

  CompArrow,
  SubArrow,
  link_ports!,
  add_sub_arr!,
  out_sub_port,
  out_sub_ports,
  sub_ports,
  in_sub_port,
  in_sub_ports,
  in_ports,
  in_port,
  in_ports,
  out_port,
  out_ports,
  num_in_ports,
  num_out_ports,
  num_ports,
  port,
  ports,
  propagate,
  is_wired_ok,
  is_valid,
  interpret,
  invert!,
  invert,
  duplify!,

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
  GatherNdArrow,
  SinArrow,
  SqrArrow,
  SqrtArrow,
  CosArrow,

  # Inverse Arrows
  InvDuplArrow,
  inv_add,
  inv_mul

include("util/misc.jl")
include("util/lightgraphs.jl")

# include("types.jl")

include("arrows/arrow.jl")
include("arrows/port.jl")
include("arrows/primarrow.jl")
include("arrows/comparrow.jl")
include("arrows/comparrowextra.jl")
include("arrows/value.jl")
include("arrows/trace.jl")
include("arrows/port_arith.jl")

# Library
include("library/common.jl")
include("library/arithmetic.jl")
include("library/control.jl")
include("library/source.jl")
include("library/array.jl")

include("library/inv_control.jl")
include("library/inv_arith.jl")
include("library/statistics.jl")

include("combinators/compose.jl")

include("apply/preddisp.jl")
include("apply/propagate.jl")
# include("apply/interpret.jl")
include("apply/depend.jl")
include("apply/policy.jl")
include("apply/compile.jl")


include("transform/walk.jl")
include("transform/duplify.jl")
include("transform/invert.jl")
include("transform/totalize.jl")


include("optim/loss.jl")

# include("library.jl")

include("targets/julia/julia.jl")
include("targets/tensorflow/tensorflow.jl") # TODO Make optional

include("../test/TestArrows.jl")

# include("smt_solvers/z3interface.jl")
end
