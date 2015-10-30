## Type Checking
## =============

import Z3

# "Constructs map from symbol names to (SMT) variables"
# function uniquevariables(atyp::ArrowType)
#   typvarnames = typevars(atype)
#   typevars = map(Var, typevarnames)
#   Dict(zip(typvarnames, typevars)
# end

"Convert an integer into an SMT integer"
function SMTify(v::Integer, ctx::Z3.Context)
  @show x
  Z3.NumeralAst(Integer, v; ctx=ctx)
end

"Convert a parameter into an SMT variable"
function SMTify{T}(x::Parameter{T}, ctx::Z3.Context)
  @show x
  Z3.Var(Integer; name = string(x.name), ctx=ctx)
end

"Are the dimensions compatible, if so return model"
function typeparamsdims(a::CompositeArrow)
  Z3.disable_global_ctx!()
  ctx = Z3.Context()
  slv = Z3.Solver(;ctx=ctx)


  ## Construct this map from ports to their dimensions
  inport2var = [inport => SMTify(ndims(a, inport), ctx) for inport in subarrowinports(a)]
  outport2var = [outport => SMTify(ndims(a, outport), ctx) for outport in subarrowoutports(a)]

  ## assert that dimensions connected by edges are equal
  for (outp, inp) in edges(a)
    if !(isboundary(outp) | isboundary(inp))
      Z3.add!((==)(outport2var[outp], inport2var[inp];ctx=ctx); solver=slv, ctx=ctx)
    end
  end

  # TOADD
  # - variable dimensions should be positive
  # - variables with same symbol should be the same variable - doofus

  @show Z3.check(;solver=slv, ctx=ctx)
  Z3.del_context(ctx)
  return Nullable{Model}(model)
end

# function typeparams(a::CompositeArrow)
# end

# """Return values for type parameters.
#
# If `unambgiuous` is true, will fail if types are ambiguous"""
# function typeparams(a::Arrow; unambgiuous = false)
#
#   # Generates type variables for each port then checks if following constraints are sat:
#   # 1. connected ports have equal types
#   # 2. all type constraints from subarrows hold
#   # 3. type constraints of a hold
#
#   edgeconstraints = Var{Bool}[]
#   for subarrow in subarrows(a)
#     # construct arrow type
#     vartype = varify(typ(subarrow))
#   end
#
#
#   # For every node we will construct all the type variables
#   # variables which are symbolically equivalent are the variable
#
#   # for every port, construct an array of integers
#
#   # assert equivalence of arrays on connecting edges
#
#   # if
# end

"Is arrow `a` type safe?"
istypesafe(a::Arrow; args...) = isnull(typeparams(a; args...))

## TODO
## =====

# 1. Group types - should fit into above Framework
# 2. type constructors - will require new framework, but this framework should remain intact as inner loop
# 3. subarrows
