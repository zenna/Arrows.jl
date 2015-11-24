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

function prefix_dimvars(a::PrimArrow, pfx::Symbol)
  dtypes = ftypes(typ(a), ndims)
  prefixed = union([prefix(parameters(dtype), pfx) for dtype in dtypes]...) # ›⋙
  paramset = ParameterSet(prefixed)
end

"Set of parameters, prefixed with the appropriate arrowname"
function prefix_dimvars(a::FlatArrow, uniq_arrnames::Vector{Symbol})
  paramset = ParameterSet()
  for i = 1:length(nodes(a))
    sbarr = nodes(a)[i]
    prefixedparams = prefix_dimvars(sbarr, uniq_arrnames[i+1])
    union!(paramset, prefixedparams)
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
      @show outexpr = exprtyp(a, outp)
      @show inexpr = exprtyp(a, inp)
      lhs = prefix(outexpr, uniq_arrnames[outp.arrowid])
      rhs = prefix(inexpr, uniq_arrnames[inp.arrowid])
      edge_constr = lhs == rhs
      push!(constraints, edge_constr)
    end
  end

  constraints
end

## Dimension Parameter checking
## ============================

"Add constraints and Check"
# TODO add type slv::SMTBase.SMTSolver
function dimaddcheck(a::FlatArrow, uniq_arrnames::Vector{Symbol}, slv)
  # Get set of constraints
  @show constraints = edgeconstraints(a, dimexpr, uniq_arrnames)

  # add constraints
  [SMTBase.add!(slv, constraint) for constraint in constraints]

  # Check whether dimensions are type safe
  @show istypesafe = SMTBase.check(slv)
end

"Replace dim type parameters with concrete values"
function reifydimtype{I, O}(a::PrimArrow{I, O}, pfx::Symbol, model::Dict)
  dtyp = dimtyp(a)
  ps = parameters(dtyp)
  warn("integer hack")
  varmap = [p => ConstantVar{Integer}(model[prefix(p, pfx)]) for p in ps]
  newdtyp = substitute(dtyp, varmap)
end

"Replace dim type parameters with concrete values"
function reifydimtype{I, O}(
    a::FlatArrow{I, O},
    uniq_arrnames::Vector{Symbol},
    model::Dict)        # e.g. arrow2_n => 5, FIXME, make type tighter Parameter => Any
  c = CompositeArrow{I, O}
  for i = 1:length(nodes(a))
    reifydimtype(nodes(a)[i], uniq_arrnames[i+1], model)
  end
end

"""Make type parameters concrete.
If dimensions are consistent, return an arrow with a non-parametric
dimensionality type.  Otherwise return a NullAble{ArrowType}()"""
function reifydimparams(a::FlatArrow; Solver = Z3.SMTBaseInterface.Z3Solver)
  # Give a unique name to each subarrow, so as to not confuse type var names
  uniq_arrnames = mk_uniq_arrnames(a)
  slv = SMTBase.solver(Solver)
  istypesafe = dimaddcheck(a, uniq_arrnames, slv)

  if isnull(istypesafe)
    SMTBase.cleanup(slv)
    warn("""Could not determine dim-typesafety, please instantiate typevariables
            manually, try different solver or use decidable theories""")
    Nullable{FlatArrow}()
  elseif !get(istypesafe)
    SMTBase.cleanup(slv)
    Nullable{FlatArrow}()
  elseif get(istypesafe)
    @show uniq_varnames = tuple(prefix_dimvars(a, uniq_arrnames)...)
    m = SMTBase.model(slv)
    @show solution = SMTBase.interpret(slv, m, uniq_varnames)
    reifydimtype(a, uniq_arrnames, Dict(zip(uniq_varnames, solution)))
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
  [SMTBase.add!(slv, constraint) for constraint in constraints]

  # Check whether dimensions are type safe
  @show istypesafe = SMTBase.check(slv)
end


"How is this supposed to work?"
function shapeparams(a::FlatArrow; Solver = SMTBase.Z3Solver)
  @assert !isdimpolymorphic(a) "Works only on types which are not polymorphic in dimension"
  uniq_arrnames = mk_uniq_arrnames(a)
  slv = SMTBase.solver(Solver)
  istypesafe = shapeaddcheck(a, uniq_arrnames)
end

# """Typecheck and return arrow with all parameters resolved.
# Returns arrows without polymorphic type, or return Nullable{Arrow}()"""
# function allparams(a::FlatArrow; unambgiuous = false)
#   uniq_arrnames = mk_uniq_arrnames(a)
#   slv = SMTBase.solver(Solver)
#   typemdoel = addcheck(a, uniq_arrnames)
#
# end

"Is arrow `a` type safe?"
istypesafe(a::Arrow; args...) = isnull(typeparams(a; args...))
