module Library

using Spec

using AutoHashEquals: @auto_hash_equals
using ..ArrowMod
using ..Propagates: AbVals, IdAbVals, TraceAbVals, NmAbVals, SprtAbVals, PrtAbVals, XAbVals
import ..ArrowMod: props, name

map(eval, names(ArrowMod))

export   SourceArrow,
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
  IntDivArrow,
  IntMulArrow,
  IdentityArrow,
  ExpArrow,
  NegArrow,
  AndArrow,
  OrArrow,
  NotArrow,
  XorArrow,
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
  ReduceMeanArrow,
  FirstArrow,
  ReshapeArrow,
  ReduceVarArrow,
  AbsArrow,
  ReduceSumArrow,
  CatArrow,
  InvCatArrow,
  IntToOneHot,
  OneHotToInt,

  # Inverse Arrows
  InvDuplArrow,
  inv_add,
  inv_mul,
  ExplicitInvBroadcastArrow,
  ExplicitBroadcastArrow,
  BroadcastArrow
  
export   dupl,
         inv_dupl,
         first_arr,
         assert!,
         name

include("common.jl")
include("distances.jl")
include("sigmoid.jl")

include("assert.jl")
include("source.jl")
include("broadcast.jl")

include("arithmetic.jl")
include("inequalities.jl")
include("dupl.jl")
include("control.jl")
include("array.jl")
include("onehot.jl")
include("compound.jl")
include("statistics.jl")
include("boolean.jl")
include("md2.jl")

# Inv Arrows
include("inv_control.jl")
include("inv_array.jl")
include("inv_arithmetic.jl")
include("inv_boolean.jl")

# PGF Primitives
include("pgfprim.jl")


end