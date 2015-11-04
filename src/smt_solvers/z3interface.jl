## SMT Interface
## =============
module Z3Interface
import Z3
import Arrows: Variable, TransformedParameter, ConstantVar, Parameter, ConstrainedParameter
import Arrows: head, args

# Globals will juist cause trouble
Z3.disable_global_ctx!()
Z3.disable_global_solver!()
# import SMTBase: check, solver, add!, pop!, push!

## Implement the SMTBase Interface
## ===============================

abstract SMTSolver

typealias SymbToVar Dict{Variable, Any}

type Z3Solver <: SMTSolver
  ctx::Z3.Context
  slv::Z3.Solver
  sym_to_var::SymbToVar
end

abstract SMTModel

type Z3Model <: SMTModel
  m::Z3.Model
end

"Convert an LBool to a Nullable{Bool}"
function convert(::Type{Nullable{Bool}}, b::Z3.Z3_lbool)
  if b == Z3.Z3_L_TRUE
    Nullable{Bool}(true)
  elseif b == Z3.Z3_L_FALSE
    Nullable{Bool}(false)
  elseif b == Z3.Z3_UNDEF
    Nullable{Bool}()
  end
end

"Create a new solver"
function solver(::Type{Z3Solver})
  ctx = Z3.Context()
  slv = Z3.Solver(;ctx=ctx)
  Z3Solver(ctx, slv, SymbToVar())
end

"Check whether constraints are satisfiable"
check(slv::Z3Solver) = convert(Nullable{Bool}, Z3.check(;solver=slv.slv, ctx=slv.ctx))

"Add a constraint to the solver"
function add!(slv::Z3Solver, v::Variable{Bool})
  ex = ast(slv, v)
  Z3.add!(ex; solver=slv.slv, ctx=slv.ctx)
end

function model(slv::Z3Solver)
  Z3Model(Z3.model(; solver=slv.slv, ctx=slv.ctx))
end

"In model `m` interpret symbols vs"
function interpret(slv::Z3Solver, m::Z3Model, vs::Tuple{Vararg{Variable}})
  getast = v->expand(v, slv.sym_to_var, Set{Variable}([v]), slv.ctx)
  warn("Hacked in Integer")
  Z3.interpret(Int, m.m, map(getast, vs); ctx=slv.ctx)
end

cleanup(slv::Z3Solver) = (Z3.del_context(slv.ctx); slv.sym_to_var = SymbToVar())

## Internal Stuff
## ==============

"Construct Z3.ddVariable from Symbolic ddVariable"
function ast(slv::Z3Solver, v::Variable)
  to_visit = Set{Variable}([v])
  asts = Any[]
  while !isempty(to_visit)
    @show current_v = pop!(to_visit)
    @show ex = expand(current_v, slv.sym_to_var, to_visit, slv.ctx)
    @show push!(asts, ex)
    println()
  end
  # Conjoin all constraints
  (&)(asts...;ctx=slv.ctx)
end

function expand{T<:TransformedParameter}(p::T,
    sym_to_var::SymbToVar,
    to_visit::Set{Variable},
    ctx::Z3.Context)
  rvargs = [expand(arg, sym_to_var, to_visit, ctx) for arg in args(p)]
  func = eval(head(p))
  func(rvargs...; ctx=ctx)
end

function expand{T}(
    p::Parameter{T},
    sym_to_var::SymbToVar,
    to_visit::Set{Variable},
    ctx::Z3.Context)
  if haskey(sym_to_var, p)
    sym_to_var[p]
  else
    sym_to_var[p] = Z3.Var(T; ctx=ctx)
  end
end

# 5. If Constant just return value
function expand{T}(
    p::ConstantVar{T},
    sym_to_var::SymbToVar,
    to_visit::Set{Variable},
    ctx::Z3.Context)
  warn("int type hack")
  Z3.NumeralAst(Integer, p.val; ctx = ctx)
end

function expand{T}(
    p::ConstrainedParameter{T},
    sym_to_var::SymbToVar,
    to_visit::Set{Variable},
    ctx::Z3.Context)
  union!(to_visit, p.constraints)
  expand(p.param, sym_to_var, to_visit, ctx)
end

end
