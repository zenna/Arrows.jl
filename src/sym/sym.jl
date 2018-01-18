## PureSymbolic = Union{Expr, Symbol}
## SymUnion = Union{PureSymbolic, Array, Tuple, Number}
using NamedTuples
import DataStructures: DefaultDict

# Zen: Is this a union of a variable an expression?
mutable struct SymUnion
  value
end
token_name = :τᵗᵒᵏᵉⁿ
SymPlaceHolder() = SymUnion(token_name)

"Refined Symbol ``{x | pred}``"
struct RefinedSym
  var::SymUnion
  preds::Set{} # Conjunction of predicates
end

# Zen: Prx = Prefix?
struct SymbolPrx
  var::SymUnion
end

# Zen. Why does this function exist?
as_expr{N}(values::Union{NTuple{N, SymUnion}, AbstractArray{SymUnion, N}}) =
  map(as_expr, values)
as_expr(sym::SymUnion) = sym.value
as_expr(ref::Union{RefinedSym, SymbolPrx}) = as_expr(ref.var)
sym_unsym{N}(sym::NTuple{N, SymUnion}) = SymUnion(as_expr.(sym))
sym_unsym{N}(sym::Array{SymUnion, N}) = SymUnion(as_expr.(sym))
sym_unsym(sym::SymUnion) = sym

# Zen: This kind of object scares me
mutable struct ConstraintInfo
  exprs::Vector{Expr}
  θs::Set{Union{Symbol, Expr}}
  is_θ_by_portn::Vector{Bool}
  mapping::DefaultDict
  unsat::Set{SymUnion}
  assignments::Dict
  specials::Dict
  assigns_by_portn::Vector
  unassigns_by_portn::Vector
  specials_by_portn::Vector
  inp::Vector{RefinedSym}
  port_to_index::Dict{SymUnion, Number}
  master_carr::CompArrow
  names_to_inital_sarr::Dict{Union{Symbol, Expr}, SubArrow}
  function ConstraintInfo()
    c = new()
    c.mapping = DefaultDict(Set{Expr})
    c.unsat = Set{SymUnion}()
    c.assignments = Dict()
    c.specials = Dict()
    c.names_to_inital_sarr = Dict()
    c.port_to_index = Dict{SymUnion, Number}()
    c
  end
end

function getindex(s::SymbolPrx, i::Int)
  inner_getindex(v) = v
  inner_getindex(v::Array) = getindex(v,i)
  inner_getindex(v::Union{Symbol, Expr}) = Expr(:ref, v, i)
  s |> as_expr |> inner_getindex |> SymUnion
end

"Unconstrained Symbol"
RefinedSym(sym::SymUnion) = RefinedSym(sym, Set{SymUnion}())

# Zen. There is no Sym type, If this is outer constructo for SymUnion it should be
# called SymUnion
function Sym(prps::Props)
  # TODO: Add Type assumption
  ustring = string(name(prps))
  SymUnion(Symbol(ustring))
end
Sym(sprt::SubPort) = sprt |> deref |> Sym
Sym(prt::Port) = prt |> props |> Sym
RefinedSym(prt::Port) = RefinedSym(Sym(prt))

function sym_interpret(x::SourceArrow, args)::Vector{RefinedSym}
  [RefinedSym(SymUnion(x.value))]
end

function sym_interpret(parr::PrimArrow, args::Vector{RefinedSym})::Vector
  @show args
  @show typeof(args)
  @grab args
  vars = [SymUnion.(as_expr(arg)) for arg in args]
  @grab vars
  preds = Set[arg.preds for arg in args]
  @show parr
  @show outputs = prim_sym_interpret(parr, vars...)
  dompreds = domainpreds(parr, vars...)
  allpreds = union(dompreds, preds...)
  f = var -> RefinedSym(var, allpreds)
  if length(outputs) > 0 && isa(outputs[1], Array)
    sym_unions::Vector{SymUnion} = Array{SymUnion, ndims(outputs)}(size(outputs)...)
    for iter in eachindex(outputs)
      sym_unions[iter] = sym_unsym(outputs[iter])
    end
  else
    sym_unions = outputs
  end
  map(f, sym_unions)
end

sym_interpret(sarr::SubArrow, args) = sym_interpret(deref(sarr), args)
sym_interpret(carr::CompArrow, args) =
  interpret(sym_interpret, carr, args)

"Constraints on inputs to `carr`"
function constraints(carr::CompArrow, initprops)
  info = ConstraintInfo()
  symbol_in_ports!(carr, info, initprops)
  outs = interpret(sym_interpret, carr, info.inp)
  allpreds = reduce(union, (out->out.preds).(outs))
  preds_with_outs = union(allpreds, map(out->out.var, outs))
  filter_gather_θ!(carr, info, preds_with_outs)
  add_preds(info, allpreds)
  info
  #filter(pred -> pred ∉ remove, allpreds)
end
