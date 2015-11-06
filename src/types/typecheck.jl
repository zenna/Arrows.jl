## Type checking
## =============

# Requirements
# 1.take an arrow and type check it
# 2. Take an arrow and resolve its dimensionality parameters to return arrow polymorphic only in shape
# 3. Take an arrow and resolve all its parameters, to return non-polymorphic arrow

# TODO
## Convert a model of dim paramters into a non-dim-polymorphic type
## Check whether a type is polynorphic in dim
## Replace the type of an arrow

"A flat arrow has only primitive arrows as its subarrows. TODO: make this a real type"
typealias FlatArrow CompositeArrow

"A vector of unique names for arrow and its subarrows"
mk_uniq_arrnames(a::Arrow) =
  [symbol(genvar("arrow")) for i = 1:(nnodes(a) + 1)] # +1 to include parent

"Set of parameters, prefixed with the appropriate arrowname"
function prefix_dimvars(a::FlatArrow, uniq_arrnames::Vector{Symbol})
  paramset = Set{Parameter}()
  for i = 1:length(nodes(a))
    ps = parameters(dimtyp(nodes(a)[i]))
    [push!(paramset, prefix(p, uniq_arrnames[i+1])) for p in ps]
  end
  paramset
end

## Compiling Constraints
## =====================
"Collect constraints from each subarrow and parent arrow"
function alldimconstraints(a::FlatArrow, uniq_arrnames::Vector{Symbol})
  constraints = ConstraintSet()
  push!(constraints, [substitute(expr, varmap) for expr in alldimconstraints(a)]...)
end

"Extract constraints on dimensions of an arrow"
function edgeconstraints(a::FlatArrow, exprtyp::Function, uniq_arrnames::Vector{Symbol})
  constraints = ConstraintSet()

  # Collect constraints x == y, for each (x, y) ∈ edges(a)
  for (outp, inp) in edges(a)
    # FIXME, add constraints from boundaries
    if !(isboundary(outp) || isboundary(inp))
      outexpr = exprtyp(a, outp)
      inexpr = exprtyp(a, inp)
      lh = prefix(outexpr, uniq_arrnames[outp.arrowid])
      rh = prefix(inexpr, uniq_arrnames[inp.arrowid])
      edge_constr = lh == rh
      push!(constraints, edge_constr)
    end
  end

  constraints
end

## Dimension Parameter checking
## ============================

"Add constraints and Check"
# TODO add type slv::Arrows.Z3Interface.SMTSolver
function dimaddcheck(a::FlatArrow, uniq_arrnames::Vector{Symbol}, slv)
  # Get set of constraints
  @show constraints = edgeconstraints(a, dimexpr, uniq_arrnames)

  # add constraints
  [Arrows.Z3Interface.add!(slv, constraint) for constraint in constraints]

  # Check whether dimensions are type safe
  @show istypesafe = Arrows.Z3Interface.check(slv)
end

"""Are the dimensions consistent? if so return an arrow with a non-parametric
dimensionality type.  Otherwise return a NullAble{ArrowType}()"""
function dimparams(a::FlatArrow; Solver = Arrows.Z3Interface.Z3Solver)
  # Give a unique name to each subarrow, so as to not confuse type var names
  uniq_arrnames = mk_uniq_arrnames(a)
  slv = Arrows.Z3Interface.solver(Solver)
  istypesafe = dimaddcheck(a, uniq_arrnames, slv)

  if isnull(istypesafe)
    Arrows.Z3Interface.cleanup(slv)
    warn("""Could not determine dim-typesafety, please instantiate typevariables
            manually, try different solver or use decidable theories""")
    Nullable{FlatArrow}()
  elseif !get(istypesafe)
    Arrows.Z3Interface.cleanup(slv)
    Nullable{FlatArrow}()
  elseif get(istypesafe)
    @show uniq_varnames = tuple(prefix_dimvars(a, uniq_arrnames)...)
    m = Arrows.Z3Interface.model(slv)
    @show solution = Arrows.Z3Interface.interpret(slv, m, uniq_varnames)
  end
end

"Is it type safe in dimensionality, yes or no?!"
isdimtypesafe(a::FlatArrow; args...) = !isnull(dimparams(a;args...))

## Shape Parameter checking
## ========================

"Add constraints and Check"
function shapeaddcheck(a::FlatArrow, uniq_arrnames::Vector{Symbol})
  # Get set of constraints
  @show constraints = edgeconstraints(a, shapeexpr, uniq_arrnames)

  # add constraints
  [Arrows.Z3Interface.add!(slv, constraint) for constraint in constraints]

  # Check whether dimensions are type safe
  @show istypesafe = Arrows.Z3Interface.check(slv)
end


"How is this supposed to work?"
function shapeparams(a::FlatArrow; Solver = Arrows.Z3Interface.Z3Solver)
  @assert !isdimpolymorphic(a) "Works only on types which are not polymorphic in dimension"
  uniq_arrnames = mk_uniq_arrnames(a)
  slv = Arrows.Z3Interface.solver(Solver)
  istypesafe = shapeaddcheck(a, uniq_arrnames)
end

# """Typecheck and return arrow with all parameters resolved.
# Returns arrows without polymorphic type, or return Nullable{Arrow}()"""
# function allparams(a::FlatArrow; unambgiuous = false)
#   uniq_arrnames = mk_uniq_arrnames(a)
#   slv = Arrows.Z3Interface.solver(Solver)
#   typemdoel = addcheck(a, uniq_arrnames)
#
# end

"Is arrow `a` type safe?"
istypesafe(a::Arrow; args...) = isnull(typeparams(a; args...))
