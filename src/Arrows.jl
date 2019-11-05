"Graph-Based Program Representation"
module Arrows

using Reexport
# using ZenUtils
# import Spec: @pre, @invariant, @post

# zt: use explicit form e.g. Base.union
# import Base: convert, union, first, ndims, print, println, string, show,
#   length, isequal, eltype, hash, isequal, copy, ∘, inv, reshape,
#   map, div
# import Base: getindex, setindex!
# import Base: in
# import Base:  ^,
#               +,
#               -,
#               *,
#               /,
#               >,
#               >=,
#               <=,
#               <,
#               !=,
#               ==,
#               |,
#               &,
#               ⊻,
#               !,
#               %,
#               div,
#               cos,
#               acos,
#               sin,
#               asin,
#               log,
#               exp,
#               in,
#               sqrt,
#               abs,
#               min,
#               max,
#               parent,
#               >>,
#               <<,
#               identity,
#               zero,
#               one,
#               floor,
#               ceil,
#               getindex

export
  ifthenelse,
  lift,
  conjoin,
  disjoin,
  ∨,
  ∧,
  same,

  compose,
  wrap,
  name,

  mean,
  var,
  θp,
  ϵ,
  idϵ,
  domϵ,
  addprop!,


  # Compound
  addn,
  gather_nd,
  scatter_nd,
  
  # integer
  mul_arr,
  div,

  invcat,

  # extra arrows
  md2box,
  inverse_md2box,

  # Macros
  arr,
  transform_function,

  julia,

  # compiler
  compile,
  order_sports,

  Size,
  meetall,
  meet,

  # Symbolic Execution
  all_constraints,
  solve_scalar,

  sqr,
  mean_arr,

  onehot,
  invonehot,

  accumapply,
  trace_value,
  traceprop!,
  simpletracewalk,
  trace_values,
  is,
  add!,
  link_to_parent!,
  AbVals,
  source,
  bcast,
  exbcast,
  IdAbVals,
  NmAbVals,
  SprtAbVals,
  PrtAbVals,
  XAbVals,
  in_trace_values,
  out_trace_values,
  n▸,
  n◂,
  ▸,
  ◂,
  ▹,
  ◃,
  ⬧,
  ⬨

include("util/util.jl")             # miscelleneous utilities
@reexport using .Util

include("arrows/arrow.jl")          # Core Arrow Data structures
@reexport using .ArrowMod

include("value/value.jl")           # Graph Transformations #
@reexport using .Values

include("trace/trace.jl")
@reexport using .Trace

include("propagate/propagate.jl")   # Abstract interpretation based propagation
@reexport using .Propagates

include("library/library.jl")       # Library of arrows
@reexport using .Library

include("combinators/combinators.jl")
@reexport using .Combinators

include("compile/compile.jl")       # Compilation and application of an arrow #
@reexport using .Compile

include("transform/transform.jl")    # Graph Transformations #
@reexport using .Transform

include("macros/macros.jl")
@reexport using .Macros

include("sym/sym.jl")                # Solving constraints
@reexport using .Sym

# include("host/host.jl")            # Integration of arrow with julia #
# @reexport using .Host

include("targets/targets.jl")        # Targets
@reexport using .Targets

include("juliatarget/JuliaTarget.jl") # Julia Target
@reexport using .JuliaTarget

# Defaults
Compile.compile(arr::Arrow) = compile(arr, JuliaTarget.JLTarget)
Compile.interpret(arr::Arrow, args) = interpret(arr, args, JuliaTarget.JLTarget)


# include("homeless.jl")               # Unosrted
end
