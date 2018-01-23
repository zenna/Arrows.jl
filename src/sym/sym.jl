"`Union{Symbol, Expr}`, Either a variable an expression"
mutable struct SymUnion
  value
end

const SymbolicType = Union{Expr, Symbol, Number, AbstractArray, Tuple, NTuple}

@invariant SymUnion value isa Union{Expr, Symbol} # FIXME: Why isn't this in type?
@invariant SymUnion if value isa Union; value.head == :call else true end #FIXME< use implies

# FIXME: Label these?
token_name = :τᵗᵒᵏᵉⁿ
SymPlaceHolder() = token_name

"Refined Symbol ``{var | pred}``"
struct RefinedSym # FIXME: This should really be called a RefinementExpr
  var::SymbolicType # base expression
  preds::Set{SymbolicType}  # Conjunction of predicates
end


struct SymbolProxy
  var::SymbolicType
end


"(base) expression "
as_expr(sym::SymbolicType) = sym

""
as_expr{N}(values::Union{NTuple{N, SymbolicType}, AbstractArray{SymbolicType, N}}) =
  map(as_expr, values)

"(base) expression of `ref`"
as_expr(ref::Union{RefinedSym, SymbolProxy}) = as_expr(ref.var)


# Zen: This kind of object scares me
mutable struct ConstraintInfo
  exprs::Vector{Expr}
  θs::Set{Union{Symbol, Expr}}
  is_θ_by_portn::Vector{Bool}
  mapping::DefaultDict
  unsat::Set{SymbolicType}
  assignments::Dict
  specials::Dict
  assigns_by_portn::Vector
  unassigns_by_portn::Vector
  specials_by_portn::Vector
  inp::Vector{RefinedSym}
  port_to_index::Dict{SymbolicType, Number}
  master_carr::CompArrow
  names_to_inital_sarr::Dict{Union{Symbol, Expr}, SubArrow}
  function ConstraintInfo()
    c = new()
    c.mapping = DefaultDict(Set{Expr})
    c.unsat = Set{SymbolicType}()
    c.assignments = Dict()
    c.specials = Dict()
    c.names_to_inital_sarr = Dict()
    c.port_to_index = Dict{SymbolicType, Number}()
    c
  end
end

"Expression `:(s[i])` for symbol `s` and index `i`"
function getindex(s::SymbolProxy, i::Int)::SymbolicType
  # @show s, i
  # @assert false
  inner_getindex(v) = v
  # FIXME: This can never be called.
  # jb: SymbolProxy is a proxy for SymbolicType
  # is the proxee is an Array, then this will be actually be called
  inner_getindex(v::Array) = getindex(v, i)
  inner_getindex(v::Union{Symbol, Expr}) = Expr(:ref, v, i)
  s |> as_expr |> inner_getindex
end

"Unconstrained Symbol"
RefinedSym(sym::SymbolicType) = RefinedSym(sym, Set{SymbolicType}())


"`RefinedSymbol` with port_name of `prt`"
RefinedSym(prt::Port) = RefinedSym(name(prps).name)
RefinedSym(sprt::SubPort) = RefinedSym(sprt |> deref)

function sym_interpret(x::SourceArrow{T}, args)::Vector{RefinedSym} where T
  @show x
  [RefinedSym(x.value)]
end

function sym_interpret(x::SourceArrow{<:Array}, args)::Vector{RefinedSym}
  @show x
  # @assert false "why"
  [RefinedSym(x.value)]
end

function sym_interpret(parr::PrimArrow, args::Vector{RefinedSym})::Vector
  vars = [as_expr(arg) for arg in args]
  @show vars
  outputs = prim_sym_interpret(parr, vars...)

  # Find predicates from all outputs and conjoin constraints
  dompreds = domainpreds(parr, vars...)
  preds = Set[arg.preds for arg in args]
  allpreds = union(dompreds, preds...)

  @show outputs[1]
  @show outputs
  # @show vars
  # @grab vars
  # @show parr
  # @show outputs
  # @show dompreds
  # @show preds
  # @show allpreds
  # attach all constraints to all symbolic outputs of parr
  map(var -> RefinedSym(var, allpreds), outputs)
end

sym_interpret(sarr::SubArrow, args) = sym_interpret(deref(sarr), args)
sym_interpret(carr::CompArrow, args) = interpret(sym_interpret, carr, args)

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
