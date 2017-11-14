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

mutable struct ConstraintInfo
  exprs::Vector{Expr}
  θs::Set{Union{Symbol, Expr}}
  mapping::Dict
  unsat::Set{SymUnion}
  assignments::Dict
  assigns_by_portn::Vector
  unassigns_by_portn::Vector
  inp::Vector{RefnSym}
  port_to_index::Dict{SymUnion, Number}
  master_carr::CompArrow
  names_to_inital_sarr::Dict{Union{Symbol, Expr}, SubArrow}
  function ConstraintInfo()
    c = new()
    c.mapping = Dict()
    c.unsat = Set{SymUnion}()
    c.assignments = Dict()
    c.names_to_inital_sarr = Dict()
    c
  end
end

# TODO: generate this list dynamically
scalar_names = Set{Symbol}([:+, :-, :*, :/, :exp, :log, :logbase, :asin, :sin,
                            :cos, :acos, :sqrt, :sqr, :abs, :^, :min, :max,
                            :%, :ceil, :floor])
function getindex(s::SymbolPrx, i::Int)
  ref_expr = v-> Expr(:ref, v, i)
  inner_getindex(v) = v
  inner_getindex(v::Array) = getindex(v,i)
  inner_getindex(v::Union{Symbol, Expr}) = ref_expr(v)
  sym = s.var
  v = sym.value
  SymUnion(inner_getindex(v), hash(i, sym.hsh))
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
  info = ConstraintInfo()
  symbol_in_ports(carr, info)
  outs = interpret(sym_interpret, carr, info.inp)
  allpreds = Set{SymUnion}()
  foreach(out -> union!(allpreds, out.preds), outs)
  filter_gather_θ!(carr, info, allpreds)
  add_preds(info, allpreds)
  info
  #filter(pred -> pred ∉ remove, allpreds)
end


function filter_gather_θ!(carr::CompArrow, info::ConstraintInfo, constraints)
  all_gather_θ = Set{Expr}()
  non_gather_θ = Set{Union{Symbol, Expr}}()
  for (name, idx) in info.port_to_index
    exprs = info.inp[idx].var.value
    if startswith(String(name.value), String(:θgather))
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
  info.θs = union(θs, non_gather_θ)
end

function expand_θ(θ, sz::Size)
  shape = get(sz)
  symbols = Array{Arrows.SymUnion, ndims(sz)}(shape...)
  for iter in eachindex(symbols)
    symbols[iter] = θ[iter]
  end
  symbols
end

function symbol_in_ports(arr::CompArrow, info::ConstraintInfo)
  trcp = traceprop!(arr, Dict{SubPort, Arrows.AbValues}())
  info.inp = inp = (Vector{RefnSym} ∘ n▸)(arr)
  info.port_to_index = Dict{SymUnion, Number}()
  for (idx, sport) in enumerate(▹(arr))
    sym = (Sym ∘ deref)(sport)
    info.port_to_index[sym] = idx
    tv = trace_value(sport)
    if haskey(trcp, tv)
      inferred = trcp[tv]
      if haskey(inferred, :size)
        sz = inferred[:size]
        expand = x->expand_θ(x, sz)
        sym_arr = (expand ∘ SymbolPrx)(sym)
        inp[idx] = (RefnSym ∘ SymUnion)(unsym.(sym_arr))
        continue
      end
    end
    inp[idx] = RefnSym(sym)
  end
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


function add_preds(info::ConstraintInfo, allpreds::Set)
  info.exprs = unsym.(collect(allpreds))
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
  info
end


function compute_assigns_by_portn(info::ConstraintInfo)
  as_expr = x->x.var.value
  as_set(x::AbstractArray) = Set(x)
  as_set(x) = Set([x,])
  inp_set = map(as_set ∘ as_expr, info.inp)
  assigns = map(_->Dict(),info.inp)
  θs = copy(info.θs)
  for (k,v) in info.assignments
    for (id, set) in enumerate(inp_set)
      if k ∈ set
        assigns[id][k] = v
        pop!(θs, k)
      end
    end
  end
  unassigns = map(_->Set(),info.inp)
  for θ in θs
    for (id, set) in enumerate(inp_set)
      if θ ∈ set
        push!(unassigns[id], θ)
      end
    end
  end
  info.unassigns_by_portn = unassigns
  info.assigns_by_portn = assigns
end

length_of(info::Arrows.ConstraintInfo, idx) = length(info.inp[idx].var.value)

extract_index(v::Int) = v - 1
function extract_index(v::Expr)
  assert(v.head == :ref)
  extract_index(v.args[2])
end

function extract_indices(elements::AbstractArray)
    indices = map(extract_index, elements)
    n = length(indices)
    reshape(indices, (n, 1))
end

function generate_gather(carr::CompArrow, indexed_elements, shape)
  indices = extract_indices(indexed_elements)
  indices = SourceArrow(indices)
  shape = SourceArrow(shape)
  sarr_shape =  add_sub_arr!(carr, shape)
  sarr = add_sub_arr!(carr, indices)
  sarr_gather =  add_sub_arr!(carr, GatherNdArrow())
  (carr, 1) ⥅ (sarr_gather, 1)
  (sarr, 1) ⥅ (sarr_gather, 2)
  (sarr_shape, 1) ⥅ (sarr_gather, 3)
  sarr_gather
end

function generate_scatter(carr::CompArrow, indexed_elements, shape)
  indices = extract_indices(indexed_elements)
  indices = SourceArrow(indices)
  shape = SourceArrow(shape)
  sarr_shape =  add_sub_arr!(carr, shape)
  sarr = add_sub_arr!(carr, indices)
  sarr_scatter =  add_sub_arr!(carr, ScatterNdArrow())
  (sarr, 1) ⥅ (sarr_scatter, 2)
  (sarr_shape, 1) ⥅ (sarr_scatter, 3)
  (sarr_scatter, 1) ⥅ (carr, 1)
  sarr_scatter
end

# this is not ok. There are many examples that may breake this
extract_expr_modulo_index(v) = v
extract_expr_modulo_index(v::Symbol) = v
function extract_expr_modulo_index(v::Expr)
  if v.head == :ref
    extract_expr_modulo_index(v.args[1])
  else
    args = map(extract_expr_modulo_index, v.args)
    Expr(v.head, args...)
  end
end

function extract_computation_blocks(assigns)
  by_block = Dict()
  for (k,v) in assigns
    index = extract_expr_modulo_index(v)
    if !haskey(by_block, index)
      by_block[index] = Vector()
    end
    push!(by_block[index], (k, v))
  end
  by_block
end

function name(info::ConstraintInfo, idx)
  value = info.inp[idx].var.value
  if isa(value, Symbol)
    expr = value
  else
    expr = value[1]
  end
  extract_expr_modulo_index(expr)
end
function create_first_step_of_connection(info)
  for (idx, unassign) in enumerate(info.unassigns_by_portn)
    if length(unassign) > 0
      connector_arr = CompArrow(gensym(:connector_first), [:x], [:z])
      if isa(info.inp[idx].var.value, Symbol)
        sarr = Arrows.add_sub_arr!(connector_arr, IdentityArrow())
      else
        pairs = Vector()
        values = collect(unassign)
        for (id_, dst) in enumerate(sort(values, by=Arrows.extract_index))
          push!(pairs, (dst, id_))
        end
        sarr = create_inner_connector(info, connector_arr, pairs,  idx)
      end
      (connector_arr, 1) ⥅ (sarr, 1)
      (sarr, 1) ⥅ (connector_arr, 1)
      connector_sarr = add_sub_arr!(info.master_carr, connector_arr)
      info.names_to_inital_sarr[name(info, idx)] = connector_sarr
      link_to_parent!(▹(connector_sarr, 1))
    end
  end
end

function create_inner_connector(info::ConstraintInfo,
                                connector_arr::CompArrow,
                                pairs, idx)
  carr = CompArrow(gensym(:inner_connector), [:x], [:z])
  sarr = add_sub_arr!(connector_arr, carr)
  inputs = map(x->x[2], pairs)
  outputs = map(x->x[1], pairs)
  g = generate_gather(carr, inputs, size(inputs))
  s = generate_scatter(carr, outputs, length_of(info, idx))
  (g,1) ⥅ (s,1)
  sarr
end

extract_variables(v) = Set()
extract_variables(v::Symbol) = Set([v,])
function extract_variables(v::Expr)
  if v.head == :call
    args = v.args[2:end]
  else
    args = v.args
  end
  union(map(extract_variables, args)...)
end

function sarr_for_block(info::ConstraintInfo, moniker::Union{Expr, Symbol})

  if haskey(info.names_to_inital_sarr, moniker)
    info.names_to_inital_sarr[moniker]
  else
    variables = extract_variables(moniker)
    context = Dict()
    for v in variables
      sarr = sarr_for_block(info, v)
      context[v] = ◃(sarr, 1)
    end
    M = Module()
    for (k,v) in context
           eval(M, :($k = $v))
    end
    sport = eval(M, moniker)
    info.names_to_inital_sarr[moniker] = sub_arrow(sport)
  end
end

function create_assignment_graph_for(info::ConstraintInfo, idx, assigns)
    by_block = extract_computation_blocks(assigns)
    connectors = Vector()
    if isa(info.inp[idx].var.value, Symbol)
      #TODO handle equations with scalars
      warn("equations with scalars are not handled")
      return connectors
    end

    moniker = name(info, idx)
    has_initializer = haskey(info.names_to_inital_sarr, moniker)
    connector_arr = CompArrow(gensym(:connector),
                      (length ∘ keys)(by_block) + (has_initializer ? 1 :0),
                      1)
    connector_sarr = add_sub_arr!(info.master_carr, connector_arr)

    input_id = 0
    for (block, pairs) in by_block
      input_id += 1
      carr = create_inner_connector(info,
                                      connector_arr,
                                      pairs, idx)
      push!(connectors, carr)
      block_sarr = sarr_for_block(info, block)
      (block_sarr, 1) ⥅ (connector_sarr, input_id)
      (connector_arr, input_id) ⥅ (carr, 1)
    end
    if has_initializer
      initial_sarr = sarr_for_block(info, moniker)
      (connector_sarr, input_id) ⥅ (initial_sarr,1)
    end

    first = ◃(connectors[1],1)
    sport = has_initializer ? ▹(connector_arr, n▸(connector_arr)) + first : first
    foreach(connectors[2:end]) do c
      sport = sport + ◃(c, 1)
    end
    sport ⥅ (connector_arr, 1)
    connector_arr
end


"solve constraints on inputs to `carr`"
function solve(carr::CompArrow)
  info = constraints(carr)
  assigns_by_port = (compute_assigns_by_portn ∘ find_assignments)(info)
  info.master_carr = CompArrow(gensym(:solver_θ))
  create_first_step_of_connection(info)
  carrs = map(enumerate(assigns_by_port)) do args
    create_assignment_graph_for(info, args...)
  end
  carrs, info
end
