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
import NamedTuples: @NT, NamedTuple
import AutoHashEquals: @auto_hash_equals
using MacroTools
import Base: gradient

import Base: convert, union, first, ndims, print, println, string, show,
  showcompact, length, isequal, eltype, hash, isequal, copy, ∘, inv, reshape,
  map, mean
import Base: getindex, setindex!

import Base: is, in

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
              ceil,
              getindex

export
  lift,
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
  port_id,
  add_sub_arr!,
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
  out_port,
  out_ports,
  num_in_ports,
  num_out_ports,
  num_ports,
  port,
  ports,

  is_wired_ok,
  is_valid,
  interpret,
  invert,
  pgf,
  out_values,
  aprx_invert,
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
  idϵ,
  domϵ,
  addprop!,

  SourceArrow,
  AssertArrow,
  UnknownArrow,

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
  ScatterNdArrow,
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
  PowArrow,
  LogArrow,
  LogBaseArrow,
  ReduceMean,

  # Compound
  addn,
  gather_nd,

  # Optimization
  optimize,
  verify_loss,
  verify_optim,
  domain_ovrl,

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
  compile,
  order_sports,

  TestArrows,
  Size,
  meetall,
  meet,

  accumapply,
  trace_value,
  psl,
  supervised,
  traceprop!,
  simpletracewalk,
  trace_values,
  is,
  add!,
  link_to_parent!,
  AbValues,
  gradient,
  source,
  bcast,
  IdAbValues,
  NmAbValues,
  SprtAbValues,
  PrtAbValues,
  XAbValues,
  in_trace_values,
  out_trace_values,
  Sampler,
  @grab,
  δarr,
  ▸,
  ◂,
  ▹,
  ◃,
  ⬧,
  ⬨


# Code structures
include("util/misc.jl")             # miscelleneous utilities
include("util/lightgraphs.jl")      # methods that should be in LightGraphs
include("util/pre.jl")              # methods that should be in LightGraphs
include("util/generators.jl")       # methods that should be in LightGraphs

# Core Arrow Data structures #
include("arrows/arrow.jl")          # Core Arrow data structures
include("arrows/property.jl")       # Properties
include("arrows/port.jl")           # Ports
include("arrows/primarrow.jl")      # Pimritive Arrows
include("arrows/comparrow.jl")      # Composite Arrows
include("arrows/comparrowextra.jl") # functions on CompArrows that dont touch internals
include("arrows/unknown.jl")        # Unknown (uninterpreted) Arrows

include("value/value.jl")           # ValueSet
include("value/source.jl")          # SrcValue
include("arrows/trace.jl")          # Arrow Traces

# Abstract interpretation based propagation
include("propagate/meet.jl")        # Meeting (intersection) of domains
include("propagate/propagate.jl")
include("propagate/size.jl")
include("propagate/concrete.jl")
include("propagate/const.jl")           # Const type

# Library #
include("library/common.jl")
include("library/distances.jl")
include("library/sigmoid.jl")

include("library/assert.jl")
include("library/source.jl")
include("library/broadcast.jl")

include("library/arithmetic.jl")
include("library/inequalities.jl")
include("library/dupl.jl")
include("library/control.jl")
include("library/array.jl")
include("library/compound.jl")
include("library/statistics.jl")
include("library/boolean.jl")

# Inv Arrows
include("library/inv_control.jl")
include("library/inv_array.jl")
include("library/inv_arith.jl")

# PGF Primitives
include("library/pgfprim.jl")

# Arrow combinators: compose Arrows into composite arrows #
include("combinators/compose.jl")
include("combinators/portapply.jl")


# Compilation and application of an arrow #
include("compile/policy.jl")
include("compile/depend.jl")
include("compile/detpolicy.jl")
include("compile/imperative.jl")
include("apply/interpret.jl")
include("apply/traceinterpret.jl")


# Graph Transformations #
include("transform/walk.jl")
include("transform/tracewalk.jl")
include("transform/newtracewalk.jl")
include("transform/duplify.jl")
include("transform/invert.jl")
include("transform/pgf.jl")
include("transform/invprim.jl")
include("transform/compcall.jl")
include("transform/totalize.jl")
include("transform/totalizeprim.jl")
include("transform/domainerror.jl")
include("transform/domainerrorprim.jl")
include("transform/supervised.jl")

# Random generation
include("rand.jl")

# Macros
include("macros/arr_macro.jl")

# Solving constraints
# include("sym/sym.jl")

# Integration of arrow with julia #
include("host/overload.jl")
include("host/filter.jl")
include("map.jl")

# # Optimziation and Learning #
include("optim/loss.jl")
include("optim/util.jl")
include("gradient/gradient.jl")
include("optim/optimize.jl")

# # Targets #
include("targets/targets.jl")
include("targets/julia/ordered_sports.jl")

# # Compile to Julia by default
compile(arr::Arrow) = compile(arr, JuliaTarget.JLTarget)
interpret(arr::Arrow, args) = interpret(arr, args, JuliaTarget.JLTarget)

include("apply/call.jl")
include("targets/julia/JuliaTarget.jl")
include("../test/TestArrows.jl")

include("homeless.jl")    # Unosrted
end
