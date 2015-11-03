## SMT Interface
## =============
module Z3Interface
import Z3
import Arrows: Variable, TransformedParameter, ConstantVar, Parameter
Z3.disable_global_ctx!()

# import SMTBase: check, solver, add!, pop!, push!

## Implement the SMTBase Interface
## ===============================

abstract SMTSolver
type Z3Solver <: SMTSolver
  ctx::Z3.Context
  slv::Z3.Solver
end


"Create a new solver"
function solver(::Type{Z3Solver})
  ctx = Z3.Context()
  slv = Z3.Solver(;ctx=ctx)
  Z3Solver(ctx, slv)
end

"Check"
check(slv::Z3Solver) = Z3.check(;solver=slv.slv, ctx=slv.ctx)

"Get a wicked"
function add!(slv::Z3Solver, v::Variable{Bool})
  ex = ast(v, slv)
  Z3.add!(solver=Z3.slv; ctx=Z3.ctx)
end

# pop!()
#
# push!()
cleanup(slv::Z3Solver) = Z3.delete_ctx!(slv.ctx)

## Internal Stuff
## ==============

typealias SymbToVar Dict{Variable, Z3.Ast}

"Construct Z3.ddVariable from Symbolic ddVariable"
function ast(slv::Z3Solver, v::Variable)
  sym_to_var = SymbToVar()
  ex = expand(X, sym_to_var, slv.ctx)
end

function expand{T<:TransformedParameter}(p::T, sym_to_var::SymbToVar, ctx::Z3.Context)
  rvargs = [expand(arg,sym_to_var,ctx) for arg in args(X)]
  eval(head(p))(rvargs...; ctx=ctx)
end

function expand{T}(X::Parameter{T}, sym_to_var::SymbToVar, ctx::Z3.Context)
  if haskey(sym_to_var, X)
    sym_to_var[X]
  else
    sym_to_var[X] = Z3.Var(T; ctx=ctx)
  end
end

# 5. If Constant just return value
expand{T}(X::ConstantVar{T}, sym_to_var::SymbToVar, ctx::Z3.Context) = Z3.NumericAst{T}(X.val)

end
