"""Learning and inference with a P.L. twist

## Code conventions

- Use the following argument names

- `prt`: `Port`
- `sprt`: `SubPort`
- `aarr`: `AbstractArrow`
- `arr`: `Arrow`
- `carr`: `CompArrow`
- `sarr`: `SubArrow`
- `parr`: `PrimArrow`

-

Some shorthands used throughout
- `aprx`: Approximate(ly)
- `inv` : inverse, invert

"""
module Arrows

import LightGraphs; const LG = LightGraphs
import DataStructures: PriorityQueue, peek, dequeue!
using NamedTuples

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
              identity
export
  conjoin,
  disjoin,
  ∨,
  ∧,

  compose,
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
  propagate,
  is_wired_ok,
  is_valid,
  interpret,
  invert!,
  invert,
  aprx_invert,
  aprx_totalize!,
  duplify!,
  assert!,
  deref,

  SourceArrow,
  AssertArrow,

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
  SinArrow,
  SqrArrow,
  SqrtArrow,
  CosArrow,

  # Compound
  addn,

  # Inverse Arrows
  InvDuplArrow,
  inv_add,
  inv_mul,

  # Optim
  julia,
  iden_loss

include("util/misc.jl")
include("util/lightgraphs.jl")

# include("types.jl")

# Core Arrow Data structures #
include("arrows/arrow.jl")
include("arrows/port.jl")
include("arrows/primarrow.jl")
include("arrows/comparrow.jl")
include("arrows/comparrowextra.jl")
include("arrows/value.jl")
include("arrows/trace.jl")
include("arrows/label.jl")

# Library #
include("library/common.jl")

include("library/assert.jl")
include("library/source.jl")

include("library/arithmetic.jl")
include("library/inequalities.jl")
include("library/control.jl")
include("library/array.jl")
include("library/compound.jl")

include("library/inv_control.jl")
include("library/inv_arith.jl")
include("library/statistics.jl")
include("library/boolean.jl")

# Arrow combinators: compose Arrows into composite arrows #
include("combinators/compose.jl")

# Compilation and application of an arrow #
include("apply/preddisp.jl")
include("apply/propagate.jl")

include("compile/policy.jl")
include("compile/depend.jl")
include("compile/detpolicy.jl")
include("compile/imperative.jl")


include("apply/interpret.jl")

# Graph Transformations #
include("transform/walk.jl")
include("transform/duplify.jl")
include("transform/invert.jl")
include("transform/invprim.jl")
include("transform/totalize.jl")
include("transform/totalizeprim.jl")

# Integration of arrow with julia #
include("host/overload.jl")

# Optimziation and Learning #
include("optim/loss.jl")

# Examples, etc #
include("targets/targets.jl")
include("targets/julia/JuliaTarget.jl")
# include("targets/tensorflow/tensorflow.jl") # TODO Make optional

include("apply/call.jl")

include("../test/TestArrows.jl")
# include("../examples/ExampleArrows.jl")

# Analysis
include("../analysis/analysis.jl")

# include("smt_solvers/z3interface.jl")

const tcarr = TestArrows.xy_plus_x_arr()
const tsarr = sub_arrows(tcarr)[2]
export tcarr, tsarr

end
