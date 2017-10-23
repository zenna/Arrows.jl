"""Learning and inference with a P.L. twist

## Code conventions

- Functions which modify their input are suffixed !, e.g. `link_ports!`
- Use descriptive function names but appreviate variable names

- Use the following argument names

- `prt`: `Port`
- `sprt`: `SubPort`
- `aarr`: `AbstractArrow`
- `arr`: `Arrow`
- `carr`: `CompArrow`
- `sarr`: `SubArrow`
- `parr`: `PrimArrow`

Some shorthands used throughout
- `aprx`: Approximate(ly)
- `inv` : inverse, invert


- θ: parameter
- ϵ: error
"""
module Arrows

import LightGraphs; const LG = LightGraphs
import DataStructures: PriorityQueue, peek, dequeue!
using NamedTuples

import Base: convert, union, first, ndims, print, println, string, show,
  showcompact, length, isequal, eltype, hash, isequal, copy, ∘, inv

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
              %,
              cos,
              acos,
              sin,
              asin,
              log,
              exp,
              in,
              sqrt,
              abs,
              min,
              max,
              parent,
              >>,
              <<,
              dot,
              identity,
              ifelse,
              var,
              zero,
              one,
              floor,
              ceil
export
  conjoin,
  disjoin,
  ∨,
  ∧,
  same,

  compose,
  wrap,
  name,

  Arrow,
  Port,
  SubPort,

  CompArrow,
  PrimArrow,
  SubArrow,
  link_ports!,
  ⥅,
  ⥆,
  add_sub_arr!,
  rem_sub_arr,
  replace_sub_arr!,
  out_sub_port,
  out_sub_ports,
  inner_sub_ports,
  sub_arrow,
  sub_arrows,
  sub_port,
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
  propagate!,
  Shape,
  #const
  Const,
  known_const,
  known_not_const,
  const_propagator!,

  is_wired_ok,
  is_valid,
  interpret,
  invert!,
  invert,
  pgf,
  out_values,
  aprx_invert,
  aprx_totalize!,
  aprx_totalize!,
  domain_error,
  domain_error!,
  dupl,
  inv_dupl,
  duplify!,
  assert!,
  deref,

  mean,
  var,

  ◂,
  ◂,
  ▸,
  ▸,
  n◂,
  n▸,
  ◃,
  ▹,
  θp,
  ϵ,
  addprop!,

  SourceArrow,
  AssertArrow,

  MeanArrow,
  VarArrow,

  AddArrow,
  MulArrow,
  CondArrow,
  EqualArrow,
  SubtractArrow,
  DivArrow,
  IdentityArrow,
  ExpArrow,
  NegArrow,
  GatherNdArrow,
  ASinArrow,
  ACosArrow,
  SinArrow,
  SqrArrow,
  SqrtArrow,
  CosArrow,
  DuplArrow,
  ModArrow,
  FloorArrow,
  CeilArrow,

  # Compound
  addn,

  # Optimization
  optimize,

  # Inverse Arrows
  InvDuplArrow,
  inv_add,
  inv_mul,

  # Macros
  arr,
  transform_function,

  # Optim
  julia,
  id_loss,

  # compiler
  order_sports
# Code structures


include("util/misc.jl")             # miscelleneous utilities
include("util/lightgraphs.jl")      # methods that should be in LightGraphs

# include("types.jl")

# Core Arrow Data structures #
include("arrows/arrow.jl")          # Core Arrow data structures
include("arrows/property.jl")           # Ports and Port Attirbutes
include("arrows/port.jl")           # Ports and Port Attirbutes
include("arrows/primarrow.jl")      # Pimritive Arrows
include("arrows/comparrow.jl")      # Composite Arrows
include("arrows/comparrowextra.jl") # functions on CompArrows that dont touch internals

include("value/value.jl")           # ValueSet
include("value/source.jl")          # SrcValue
include("value/const.jl")           # Const type

include("arrows/trace.jl")          #

# Library #
include("library/common.jl")        # Methods common to library functions
include("library/distances.jl")     # Methods common to library functions
include("library/sigmoid.jl")     # Methods common to library functions

include("library/assert.jl")
include("library/source.jl")

include("library/arithmetic.jl")
include("library/inequalities.jl")
include("library/control.jl")
include("library/array.jl")
include("library/compound.jl")

include("library/pgfprim.jl")

include("library/inv_control.jl")
include("library/inv_arith.jl")
include("library/statistics.jl")
include("library/boolean.jl")

# Arrow combinators: compose Arrows into composite arrows #
include("combinators/compose.jl")

# Compilation and application of an arrow #
include("propagate/propagate.jl")
include("propagate/shape.jl")
include("propagate/const.jl")

include("compile/policy.jl")
include("compile/depend.jl")
include("compile/detpolicy.jl")
include("compile/imperative.jl")
include("apply/interpret.jl")

# Graph Transformations #
include("transform/walk.jl")
include("transform/duplify.jl")
include("transform/invert.jl")
include("transform/pgf.jl")
include("transform/invprim.jl")
include("transform/compcall.jl")
include("transform/totalize.jl")
include("transform/totalizeprim.jl")
include("transform/domainerror.jl")
include("transform/domainerrorprim.jl")

# Macros
include("macros/arr_macro.jl")

# Solving constraints
include("sym/sym.jl")

# Integration of arrow with julia #
include("host/overload.jl")
include("host/filter.jl")


# Optimziation and Learning #
include("optim/loss.jl")
include("optim/optimize.jl")
include("gradient/gradient.jl")


# Examples, etc #
include("targets/targets.jl")
include("targets/julia/JuliaTarget.jl")
include("targets/julia/ordered_sports.jl")
# include("targets/tensorflow/TensorFlowTarget.jl") # TODO Make optional

include("apply/call.jl")

include("../test/TestArrows.jl")
include("../benchmarks/BenchmarkArrows.jl")

# Analysis
# include("../analysis/analysis.jl")

# Just for development for
end
