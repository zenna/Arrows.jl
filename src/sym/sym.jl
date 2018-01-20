"`Union{Symbol, Expr}`, Either a variable an expression"
mutable struct SymUnion
  value
end

@invariant SymUnion value isa Union{Expr, Symbol} # FIXME: Why isn't this in type?
@invariant SymUnion if value isa Union; value.head == :call else true end #FIXME< use implies

# FIXME: Label these?
token_name = :τᵗᵒᵏᵉⁿ
SymPlaceHolder() = SymUnion(token_name)

"Refined Symbol ``{var | pred}``"
struct RefinedSym # FIXME: This should really be called a RefinementExpr
  var::SymUnion # base expression
  preds::Set{SymUnion}  # Conjunction of predicates
end


struct SymbolProxy
  var::SymUnion
end


"(base) expression "
as_expr(sym::SymUnion) = sym.value

""
as_expr{N}(values::Union{NTuple{N, SymUnion}, AbstractArray{SymUnion, N}}) =
  map(as_expr, values)

"(base) expression of `ref`"
as_expr(ref::Union{RefinedSym, SymbolProxy}) = as_expr(ref.var)

"Convert `Tuple` of symbols into a `SymUnion` representing a Tuple"
sym_unsym{N}(sym::NTuple{N, SymUnion}) = SymUnion(as_expr.(sym))

"Convert `Array` of symbols into a `Symbol` representing a `Array`"
sym_unsym{N}(sym::Array{SymUnion, N}) = SymUnion(as_expr.(sym))
sym_unsym{N}(sym::Tuple{N, SymUnion}) = SymUnion(as_expr.(sym))
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

"Expression `:(s[i])` for symbol `s` and index `i`"
function getindex(s::SymbolProxy, i::Int)::SymUnion
  # @show s, i
  # @assert false
  inner_getindex(v) = v
  inner_getindex(v::Array) = getindex(v, i) # FIXME: This can never be called
  inner_getindex(v::Union{Symbol, Expr}) = Expr(:ref, v, i)
  s |> as_expr |> inner_getindex |> SymUnion
end

"Unconstrained Symbol"
RefinedSym(sym::SymUnion) = RefinedSym(sym, Set{SymUnion}())

"`SymUnion` with name of `prps`"
function SymUnion(prps::Props)
  # TODO: Add Type assumption
  ustring = string(name(prps))
  SymUnion(Symbol(ustring))
end

SymUnion(sprt::SubPort) = sprt |> deref |> SymUnion
SymUnion(prt::Port) = prt |> props |> SymUnion

"`RefinedSymbol` with port_name of `prt`"
RefinedSym(prt::Port) = RefinedSym(SymUnion(prt))

function sym_interpret(x::SourceArrow{T}, args)::Vector{RefinedSym} where T
  @show T
  @show x
  # @assert false
  [RefinedSym(SymUnion(x.value))]
end

function sym_interpret(x::SourceArrow{<:Array}, args)::Vector{RefinedSym}
  # @assert false "why"
  [RefinedSym(SymUnion(x.value))]
end

function sym_interpret(parr::PrimArrow, args::Vector{RefinedSym})::Vector
  vars = [SymUnion.(as_expr(arg)) for arg in args]
  outputs = prim_sym_interpret(parr, vars...)

  # Find predicates from all outputs and conjoin constraints
  dompreds = domainpreds(parr, vars...)
  preds = Set[arg.preds for arg in args]
  allpreds = union(dompreds, preds...)

  # @show vars
  # @grab vars
  # @show parr
  # @show outputs
  # @show dompreds
  # @show preds
  # @show allpreds
  # attach all constraints to all symbolic outputs of parr
  map((var -> RefinedSym(var, allpreds)) ∘ sym_unsym, outputs)
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
