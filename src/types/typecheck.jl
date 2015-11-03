## Compile constraints
## ==================

"A flat arrow has only primitive arrows as its subarrows. TODO: make this a real type"
typealias FlatArrow CompositeArrow

uniquevar(T::Type) = Parameter{T}(genvar("param"))

"Return an varmap (Variable => Variable) to give unique names to dim parameters in arrow"
function unique_dimvars(d::DimType)
  paramset = parameters(d)
  varmap::VarMap = [param => uniquevar(Integer) for param in paramset]
end

"Return a flat arrow with all the parameters unique, globally"
function unique_dimvars{I, O}(a::FlatArrow{I, O})
  varmap = VarMap()         # Maps old variables to new variablees
  for arr in nodes(a)
    subvarmap = unique_dimvars(dimtyp(arr))
    merge!(varmap, subvarmap)
    # addnode!(newarr, newsubarr)
  end
  varmap
end

"Extract constraints on dimensions of an arrow"
function dimconstraints(a::FlatArrow)
  constraints = ConstraintSet()

  # Convert arrow into one where different dim variables are different
  varmap = unique_dimvars(a)

  # Collect constraints from each subarrow and parent arrow
  # push!(constraints, [substitute(expr, varmap) for expr in alldimconstraints(a)]...)

  # Collect constraints x == y, for each (x, y) ∈ edges(a)
  for (outp, inp) in edges(a)
    # FIXME, add constraints from boundaries
    if !(isboundary(outp) || isboundary(inp))
      outdimexpr = dimexpr(a, outp)
      indimexpr = dimexpr(a, outp)
      @show edge_constr = substitute(outdimexpr, varmap) == substitute(indimexpr, varmap)
      push!(constraints, edge_constr)
    end
  end

  # Return pair of constraints and mapping between variables
  (constraints, varmap)::Tuple{ConstraintSet, VarMap}
end

"Are the dimensions consistent? if so return non-parametric dimensionality type"
function typeparamsdims(a::FlatArrow)
  # Get set of constraints
  @show (constraints, varmap) = dimconstraints(a)

  # Check using SMT
  istypesafe = check(solver = Z3)
  !istypesafe && return Nullable{Model}()

  # if it is satisfiable
  model::Dict{uniquenames, values}

  # substitute in values to construct a concrete type
end

"Returns an arrow with all dimensionality parameters turned into real values"
function reifydims(a::FlatArrow)
  dimmodel = typeparamsdims(a)
  replacetyp(a, dimmodel)
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
#
# "Is arrow `a` type safe?"
# istypesafe(a::Arrow; args...) = isnull(typeparams(a; args...))

## TODO
## =====

# 1. Group types - should fit into above Framework
# 2. type constructors - will require new framework, but this framework should remain intact as inner loop
# 3. subarrows
