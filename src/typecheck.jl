## Type Checking
## =============

# Type checking in Arrows.jl serves two purposes
# 1. To determine whether a program is consistent with respect to types
# 2. To determine valid values of nondeterministic values in ArrowSets

# - a type corresponds to a set of values.  All values in a type are either
#   scalars of a partiuclar numeric type or arrays of the same type and some array dimensions
# - a composition of arrows is type consistent if the output type is the same as
#   the input type and the v
# - we have polymorphic types which are basically sets of types
# - a polymorhpic arrow takes as input a polymorphic type and returns a polymorphioc type with some constraints.  These constraints constrain the relation.
# - the composition of two polymorphic arrows is type consistent if __there exists__ some selection of types at inp A, output A, inp B, output C
# - This is equivalent to saying that the join on types must be not empty.
# - Since this is a satisfiability problem, the type systm can be expressive as any satisfiability solver

"An arrow with pins labelled with (SMT) variables"
immutable VarArrow{I, O} <: Arrow{I, O}
  arr::Arrow{I, O}
  inptypevars::Vector{Var}
  outtypevars::Vector{Var}
  function VarArrow(arr::Arrow{I, O}, inpsymbs::Vector{Symbol}, outsymbs::Vector{Symbol})
    @assert length(inpsymbs) == I
    @assert length(outsymbs) == O
    new(arr, inpsymbs, outsymbs)
  end
end

"Constructs map from symbol names to (SMT) variables"
function uniquevariables(atyp::ArrowType)
  typvarnames = typevars(atype)
  typevars = map(Var, typevarnames)
  Dict(zip(typvarnames, typevars)
end

function varify(atyp::ArrowType)
  uniquevars = uniquevariables(atyp)
  ...
end

function SMTify(v::Integer, ctx)
  Z3.NumeralAst(v::Integer; ctx = ctx)
end

function SMTify{T}(x::Parameter{T}, ctx)
  Z3.Var({T})
end

"Are the dimensions compatible, if so return model"
function typeparams(a::CompositeArrow)
  ctx = Z3.Context()
  for subarrow in subarrows(a)
    # FIXME, need to not create new variable for each ting
    inportdims = [ndims(inport) for inport in inports(subarrow)]
    outportdims = [ndims(outport) for outport in outports(subarrow)]

    ## Convert these to SMTVariables
    inportdimsz3 = [SMTify(inportdim) for inportdim in inportdims]
    outportdimsz3 = [SMTify(outportdim) for outportdim in outportdims]
  end
  for (inport, outport) in a.edges
    add!(inportdimsz3[inport.arrowid] == inportdimsz3[inport.arrowid])
  end

  check()
  return Nullable{Model}(model)
end

function typeparams(a::CompositeArrow)
end

"""Return values for type parameters.

  If `unambgiuous` is true, will fail if types are ambiguous"""
function typeparams(a::Arrow; unambgiuous = false)

  # Generates type variables for each port then checks if following constraints are sat:
  # 1. connected ports have equal types
  # 2. all type constraints from subarrows hold
  # 3. type constraints of a hold

  edgeconstraints = Var{Bool}[]
  for subarrow in subarrows(a)
    # construct arrow type
    vartype = varify(typ(subarrow))


  # For every node we will construct all the type variables
  # variables which are symbolically equivalent are the variable

  # for every port, construct an array of integers

  # assert equivalence of arrays on connecting edges

  # if
end

"Is arrow `a` type safe?"
istypesafe(a::Arrow; args...) isnull(typeparams(a; args...))

## TODO
## =====

# 1. Group types - should fit into above Framework
# 2. type constructors - will require new framework, but this framework should remain intact as inner loop
# 3. subarrows
