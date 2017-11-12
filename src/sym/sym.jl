## PureSymbolic = Union{Expr, Symbol}
##SymUnion = Union{PureSymbolic, Array, Tuple, Number}
mutable struct SymUnion
  value
  hsh::UInt
end
token_name = :τᵗᵒᵏᵉⁿ
SymUnion(value) = SymUnion(value, hash(value))
SymPlaceHolder() = SymUnion(token_name)
hash(x::SymUnion, h::UInt64) = hash(x.hsh, h)
unsym(sym::SymUnion) = sym.value
sym_unsym{N}(sym::Array{SymUnion, N})  = SymUnion(unsym.(sym))
sym_unsym(sym::SymUnion)  = sym

"Refined Symbol {x | pred}"
struct RefnSym
  var::SymUnion
  preds::Set{} # Conjunction of predicates
end

struct SymbolPrx
  var::SymUnion
end

function getindex(s::SymbolPrx, i::Int)
  sym = s.var
  v = sym.value
  if isa(v, Array)
    SymUnion(getindex(v,i))
  else
    SymUnion(Expr(:ref, sym.value, i), hash(i, sym.hsh))
  end
end

"Unconstrained Symbol"
RefnSym(sym::SymUnion) = RefnSym(sym, Set{SymUnion}())


function Sym(prps::Props)
  # TODO: Add Type assumption
  ustring = string(name(prps))
  SymUnion(Symbol(ustring))
end
Sym(prt::Port) = Sym(props(prt))
RefnSym(prt::Port) = RefnSym(Sym(prt))


domainpreds(::Arrow, args...) = Set{SymUnion}()
function domainpreds{N}(::InvDuplArrow{N}, x1::SymUnion,
                        xs::Vararg)
  symbols = map(xs) do x
    :($(x.value) == $(x1.value))
  end
  Set{SymUnion}(SymUnion.(symbols))
end

function domainpreds(::InvDuplArrow, x1::Array,
                        xs::Vararg)
  answer = Array{SymUnion, 1}()
  for x in xs
    for (left, right) in zip(x1, x)
      e = :($(left.value) == $(right.value))
      push!(answer, SymUnion(e))
    end
  end
  Set{SymUnion}(answer)
end


+(x::SymUnion, y::SymUnion) = SymUnion(:($(x.value) + $(y.value)))
-(x::SymUnion, y::SymUnion) = SymUnion(:($(x.value) - $(y.value)))
/(x::SymUnion, y::SymUnion) = SymUnion(:($(x.value) / $(y.value)))
*(x::SymUnion, y::SymUnion) = SymUnion(:($(x.value) * $(y.value)))
log(x::SymUnion)::SymUnion = SymUnion(:(log($(x.value))))
neg(x::SymUnion)::SymUnion = SymUnion(:(-$(x.value)))
var(xs::Array{SymUnion}) = SymUnion(:())

function s_arrayed(xs::Array{SymUnion}, name)
  values = [x.value for x in xs]
  SymUnion(:($(name)($(values))))
end
s_mean(xs::Array{SymUnion}) = s_arrayed(xs, :mean)
function s_var(xs::Vararg{<:Array})
  x1 = xs[1]
  answer = Array()
  f = iter-> s_arrayed([x[iter] for x in xs], :var)
  [f(iter) for iter in eachindex(x1)]
end


prim_sym_interpret(::SubtractArrow, x, y) = [x .- y,]
prim_sym_interpret(::MulArrow, x, y) = [x .* y,]
prim_sym_interpret(::AddArrow, x, y) = [x .+ y,]
prim_sym_interpret(::DivArrow, x, y) = [x ./ y,]
prim_sym_interpret(::LogArrow, x) = [log.(x),]
prim_sym_interpret(::NegArrow, x) = [neg.(x),]
prim_sym_interpret{N}(::DuplArrow{N}, x) = [x  for _ in 1:N]
function prim_sym_interpret{N}(::InvDuplArrow{N},
                                xs::Vararg{SymUnion, N})::Vector{SymUnion}
  [first(xs)]
end

function prim_sym_interpret{N}(::InvDuplArrow{N},
                                xs::Vararg)::Vector{SymUnion}
  [SymUnion(map(unsym, first(xs)))]
end

function prim_sym_interpret(::ScatterNdArrow, z, indices, shape)
  indices = map(unsym, indices)
  shape = map(unsym, shape)
  z = sym_unsym(z)
  arrayed_sym = prim_scatter_nd(SymbolPrx(z), indices, shape,
                          SymPlaceHolder())
  expr = map(sym->sym.value, arrayed_sym)
  [SymUnion(expr),]
end

function prim_sym_interpret{N}(::ReduceVarArrow{N}, xs::Vararg)
  [s_arrayed([sym_unsym(x) for x in xs], :reduce_var),]
end

function prim_sym_interpret{N}(::MeanArrow{N}, xs::Vararg)
  [s_arrayed([sym_unsym(x) for x in xs], :mean),]
end

function  prim_sym_interpret(::Arrows.ReshapeArrow, data::Arrows.SymUnion,
                            shape)
  shape = sym_unsym(shape)
  expr = :(reshape($(data.value), $(shape.value)))
  [SymUnion(expr),]
end

function sym_interpret(x::SourceArrow, args)::Vector{RefnSym}
  [RefnSym(SymUnion(x.value))]
end


function sym_interpret(parr::PrimArrow, args::Vector{RefnSym})::Vector
  vars = [SymUnion.(arg.var.value) for arg in args]
  preds = Set[arg.preds for arg in args]
  outputs = prim_sym_interpret(parr, vars...)
  dompreds = domainpreds(parr, vars...)
  allpreds = union(dompreds, preds...)
  f = var -> RefnSym(var, allpreds)
  if length(outputs) > 0 && isa(outputs[1], Array)
    sym_unions = Array{SymUnion, ndims(outputs)}(size(outputs)...)
    for iter in eachindex(outputs)
      sym_output = SymUnion(map(unsym, outputs[iter]))
      sym_unions[iter] =  sym_output
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
  function constraints(carr::CompArrow)
    inp = symbol_in_ports(carr)
    outs = interpret(sym_interpret, carr, inp)
    allpreds = Set{SymUnion}()
    foreach(out -> union!(allpreds, out.preds), outs)
    θs = filter_gather_θ!(carr, inp, allpreds)
    ConstraintInfo(allpreds, θs)
    #filter(pred -> pred ∉ remove, allpreds)
  end

function filter_gather_θ!(carr::CompArrow, ports, constraints)
  inp = map(Arrows.Sym, ▸(carr))
  all_gather_θ = Set{Expr}()
  non_gather_θ = Set{Union{Symbol, Expr}}()
  for (id, p) in enumerate(inp)
    exprs = ports[id].var.value
    if startswith(String(p.value), String(:θgather))
      union!(all_gather_θ, exprs)
    else
      if isa(exprs, AbstractArray)
        union!(non_gather_θ, exprs)
      else
        push!(non_gather_θ, exprs)
      end
    end
  end
  θs = Set{Expr}()
  g = (x->find_gather_params!(x, θs)) ∘ Arrows.unsym
  foreach(g, constraints)
  unused_θ = setdiff(all_gather_θ, θs)
  foreach(constraints) do cons
    remove_unused_θs!(cons.value, unused_θ)
  end
  union(θs, non_gather_θ)
end

function expand_θ(θ, sz::Size)
  shape = get(sz)
  symbols = Array{Arrows.SymUnion, ndims(sz)}(shape...)
  for iter in eachindex(symbols)
    symbols[iter] = θ[iter]
  end
  symbols
end

function symbol_in_ports(arr::CompArrow)
  trcp = traceprop!(arr, Dict{SubPort, Arrows.AbValues}())
  inp = (Vector{RefnSym} ∘ n▸)(arr)
  for (id, sport) in enumerate(▹(arr))
    sym = (Sym ∘ deref)(sport)
    tv = trace_value(sport)
    if haskey(trcp, tv)
      inferred = trcp[tv]
      if haskey(inferred, :size)
        sz = inferred[:size]
        expand = x->expand_θ(x, sz)
        sym_arr = (expand ∘ SymbolPrx)(sym)
        inp[id] = (RefnSym ∘ SymUnion)(unsym.(sym_arr))
        continue
      end
    end
    inp[id] = RefnSym(sym)
  end
  inp
end


find_gather_params!(expr, θs) = expr
find_gather_params!(expr::Array, θs) = map(e->find_gather_params!(e, θs), expr)
function find_gather_params!(expr::Expr, θs)
  if expr.head == :call
    if expr.args[1] == :+ && Arrows.token_name ∈ expr.args
      id = expr.args[2] == Arrows.token_name ? 3 : 2
      ref = expr.args[id]
      push!(θs, ref)
      return ref
    end
  end
  expr.args = map(x->find_gather_params!(x, θs), expr.args)
  expr
end


remove_unused_θs!(expr, θs) = expr
function remove_unused_θs!(expr::Expr, θs)
  if expr.head == :call
    if expr.args[1] == :+
      if (expr.args[2] ∈ θs) || (expr.args[3] ∈ θs)
        id = expr.args[2] ∈ θs ? 3 : 2
        return expr.args[id]
      end
    end
  end
  expr.args = map(x->remove_unused_θs!(x, θs), expr.args)
  expr
end


function replace!(left::Union{Expr, Symbol}, right, expr::Expr)
  for (id, e) in enumerate(expr.args)
    if e == left
      expr.args[id] = right
    end
  end
end




symbolic_includes(left, right) = false
symbolic_includes(left::Symbol, right::Symbol) = left == right
function symbolic_includes(left, right::Expr)
  if left == right
    return true
  end
  for arg in right.args
    if symbolic_includes(left, arg)
      return true
    end
  end
  false
end

assign_if_possible(info, left, right) = false
function assign_if_possible(info, left::Union{Symbol, Expr}, right)
  if left ∉ info.θs
    return false
  end
  if symbolic_includes(left, right)
    warn("""parameters that appear in both sides of equalities cannot be
    solved""")
    false
  elseif left != right
    info.assignments[left] = right
    if haskey(info.mapping, left)
      foreach(info.mapping[left]) do expr
        replace!(left, right, expr)
      end
    end
    true
  end
end

mutable struct ConstraintInfo
  exprs::Vector{Expr}
  θs::Set{Union{Symbol, Expr}}
  mapping::Dict
  unsat::Set{SymUnion}
  assignments::Dict
  function ConstraintInfo(allpreds::Set, θs)
    c = new()
    c.exprs = unsym.(collect(allpreds))
    c.θs = θs
    c.mapping = Dict()
    c.unsat = Set{SymUnion}()
    c.assignments = Dict()
    c
  end
end

function build_symbol_to_constraint(info::ConstraintInfo)
  foreach(info.exprs) do expr
    f = x -> build_symbol_to_constraint(info, x)
    foreach(f, expr.args[2:end])
  end
end

build_symbol_to_constraint(info::ConstraintInfo, expr) = false

function build_symbol_to_constraint(info::ConstraintInfo, expr::Expr)
  for arg in expr.args
    if arg ∈ info.θs
      if !haskey(info.mapping, arg)
        info.mapping[arg] = Set{Expr}()
      end
      push!(info.mapping[arg], expr)
    else
      build_symbol_to_constraint(info, arg)
    end
  end
end
function find_assignments(info)
  build_symbol_to_constraint(info)
  for expr in info.exprs
    @assert expr.head == :call
    @assert expr.args[1] == :(==)
    left, right = expr.args[2:end]
    f = (l, r) -> assign_if_possible(info, l, r)
    !f(left, right) && !f(right, left) && push!(info.unsat, SymUnion(expr))
  end
end
