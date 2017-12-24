## PureSymbolic = Union{Expr, Symbol}
##SymUnion = Union{PureSymbolic, Array, Tuple, Number}
using NamedTuples
import DataStructures: DefaultDict

mutable struct SymUnion
  value
end
token_name = :τᵗᵒᵏᵉⁿ
SymPlaceHolder() = SymUnion(token_name)

"Refined Symbol {x | pred}"
struct RefnSym
  var::SymUnion
  preds::Set{} # Conjunction of predicates
end

struct SymbolPrx
  var::SymUnion
end

as_expr{N}(values::Union{NTuple{N, SymUnion}, AbstractArray{SymUnion, N}}) =
  map(as_expr, values)
as_expr(sym::SymUnion) = sym.value
as_expr(ref::Union{RefnSym, SymbolPrx}) = as_expr(ref.var)
sym_unsym{N}(sym::Array{SymUnion, N})  = SymUnion(as_expr.(sym))
sym_unsym(sym::SymUnion)  = sym


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
  inp::Vector{RefnSym}
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
RefnSym(sym::SymUnion) = RefnSym(sym, Set{SymUnion}())


function Sym(prps::Props)
  # TODO: Add Type assumption
  ustring = string(name(prps))
  SymUnion(Symbol(ustring))
end
Sym(sprt::SubPort) = sprt |> deref |> Sym
Sym(prt::Port) = prt |> props |> Sym
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
exp(x::SymUnion)::SymUnion = SymUnion(:(exp($(x.value))))
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
prim_sym_interpret(::ExpArrow, x) = [exp.(x),]
prim_sym_interpret(::NegArrow, x) = [neg.(x),]
prim_sym_interpret(::Arrows.BroadcastArrow, x) = [x,]
prim_sym_interpret{N}(::DuplArrow{N}, x) = [x  for _ in 1:N]
function prim_sym_interpret{N}(::InvDuplArrow{N},
                                xs::Vararg{SymUnion, N})::Vector{SymUnion}
  [first(xs)]
end

function prim_sym_interpret{N}(::InvDuplArrow{N},
                                xs::Vararg)::Vector{SymUnion}
  [xs |> first |> sym_unsym,]
end

function  prim_sym_interpret(::Arrows.ReshapeArrow,
                              data::Array{Arrows.SymUnion,2},
                              shape::Array{Arrows.SymUnion,1})
  data = as_expr(data)
  shape = as_expr(shape)
  [SymUnion(reshape(data, shape)),]

end

function prim_sym_interpret(::ScatterNdArrow, z, indices, shape)
  indices = as_expr(indices)
  shape = as_expr(shape)
  z = sym_unsym(z)
  arrayed_sym = prim_scatter_nd(SymbolPrx(z), indices, shape,
                          SymPlaceHolder())
  [sym_unsym(arrayed_sym),]
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
  vars = [SymUnion.(as_expr(arg)) for arg in args]
  preds = Set[arg.preds for arg in args]
  outputs = prim_sym_interpret(parr, vars...)
  dompreds = domainpreds(parr, vars...)
  allpreds = union(dompreds, preds...)
  f = var -> RefnSym(var, allpreds)
  if length(outputs) > 0 && isa(outputs[1], Array)
    sym_unions = Array{SymUnion, ndims(outputs)}(size(outputs)...)
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
  symbol_in_ports(carr, info, initprops)
  outs = interpret(sym_interpret, carr, info.inp)
  allpreds = reduce(union, (out->out.preds).(outs))
  preds_with_outs = union(allpreds, map(out->out.var, outs))
  filter_gather_θ!(carr, info, preds_with_outs)
  add_preds(info, allpreds)
  info
  #filter(pred -> pred ∉ remove, allpreds)
end

## This is a complex function and it's because of inv_gather
## When computing the inverse of gather, we create a CompArrow
## This CompArrow includes a ScatterNdArrow And a AddArrow that
## fills the result with the θ.
## To know which are the actual θ used, we cannot solve it in sym_interpret
## because of the composite. So, in sym_interpret we add a placeholder
## and then we collect everything named θgather that is not with the placeholder
function filter_gather_θ!(carr::CompArrow, info::ConstraintInfo, constraints)
  all_gather_θ = Set{Expr}()
  non_gather_θ = Set{Union{Symbol, Expr}}()
  for (name, idx) in info.port_to_index
    info.is_θ_by_portn[idx] || continue
    exprs = info.inp[idx] |> as_expr
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
  foreach(constraints) do cons
    find_gather_params!(as_expr(cons), θs)
  end
  unused_θ = setdiff(all_gather_θ, θs)
  foreach(constraints) do cons
    remove_unused_θs!(cons.value, unused_θ)
  end
  info.θs = union(θs, non_gather_θ)
end

function expand_θ(θ, sz::Size)::RefnSym
  shape = get(sz)
  symbols = Array{Arrows.SymUnion, ndims(sz)}(shape...)
  for iter in eachindex(symbols)
    symbols[iter] = θ[iter]
  end
  symbols |> sym_unsym |> RefnSym
end

function symbol_in_ports(arr::CompArrow, info::ConstraintInfo, initprops)
  trcp = traceprop!(arr, initprops)
  info.inp = inp = (Vector{RefnSym} ∘ n▸)(arr)
  info.is_θ_by_portn = (Vector{Bool} ∘ n▸)(arr)
  for (idx, sport) in enumerate(▹(arr))
    info.is_θ_by_portn[idx] = is(θp)(sport)
    sym = Sym(sport)
    info.port_to_index[sym] = idx
    true_ = function(size)
      prx = SymbolPrx(sym)
      expand_θ(prx, size)
    end
    inp[idx] = if_symbol_on_sport(trcp, :size, sport,
                                  true_,
                                  ()-> RefnSym(sym))
  end
end


find_gather_params!(expr, θs) = expr
find_gather_params!(expr::Array, θs) = map(e->find_gather_params!(e, θs), expr)
function find_gather_params!(expr::Expr, θs)
  if expr.head == :call
    if expr.args[1] == :+
      left, right = expr.args[2:end]
      if Arrows.token_name ∈ (left, right)
        ref = left == Arrows.token_name ? right : left
        push!(θs, ref)
        return ref
      end
    end
  end
  expr.args = map(x->find_gather_params!(x, θs), expr.args)
  expr
end


remove_unused_θs!(expr, θs) = expr
function remove_unused_θs!(expr::Expr, θs)
  if expr.head == :call
    if expr.args[1] == :+
      left, right = expr.args[2:end]
      if left ∈ θs || right ∈ θs
        return left ∈ θs ? right : left
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


collect_symbols_solver(info, v, seen) = seen
collect_symbols_solver(info, v::Symbol, seen) = (v ∈ info.θs) && push!(seen, v)
function collect_symbols_solver(info, v::Expr, seen)
  if v.head == :ref && (v ∈ info.θs)
      push!(seen, v)
  else
    foreach(v.args) do arg
      collect_symbols_solver(info, arg, seen)
    end
  end
  seen
end
"""A special assigment appears when having constraint of the
form `f(x) = g(y)` and `g⁻¹` exists"""
assign_special_if_possible(info, left, right) = false
function assign_special_if_possible(info, left::Union{Symbol, Expr}, right)
  seen_l = collect_symbols_solver(info, left, Set())
  if length(seen_l) != 1
    return false
  end
  left_name = pop!(seen_l)
  if symbolic_includes(left_name, right)
    warn("""parameters that appear in both sides of equalities
            cannot be solved: $(left) == $(right)""")
    false
  else
    if left_name ∈ keys(info.mapping)
      foreach(info.mapping[left_name]) do expr
        if !symbolic_includes(expr, left)
          return false
        end
      end
    end
    info.specials[left_name] = @NT(dst = left, src = right)
    true
  end
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
    if left ∈ keys(info.mapping)
      foreach(info.mapping[left]) do expr
        replace!(left, right, expr)
      end
    end
    true
  end
end


function add_preds(info::ConstraintInfo, allpreds::Set)
  info.exprs = allpreds |> collect |> as_expr
end

function build_symbol_to_constraint(info::ConstraintInfo)
  foreach(info.exprs) do expr
    build_symbol_to_constraint(info, expr)
  end
end

"creates a mapping from symbols to the expressions that used them"
build_symbol_to_constraint(info::ConstraintInfo, expr) = false
function build_symbol_to_constraint(info::ConstraintInfo, expr::Expr)
  for arg in expr.args
    if arg ∈ info.θs
      push!(info.mapping[arg], expr)
    else
      build_symbol_to_constraint(info, arg)
    end
  end
end

"""Try to find an assigment like a == b or b == a.
Additionally, it try to find an assigment of the form
f(a) = b, when f is a total function and f⁻¹ exists."""
function find_assignments(info)
  build_symbol_to_constraint(info)
  for expr in info.exprs
    @assert expr.head == :call
    @assert expr.args[1] == :(==)
    left, right = expr.args[2:end]
    assign = (l, r) -> assign_if_possible(info, l, r)
    special = (l, r) -> assign_special_if_possible(info, l, r)
    if !assign(left, right) && !assign(right, left)
      if !special(left, right) && !special(right, left)
        push!(info.unsat, SymUnion(expr))
      end
    end
  end
  info
end

"Function that separate [assgins,specials] by port number"
function compute_assigns_by_portn(info::ConstraintInfo)
  as_set(x::AbstractArray) = Set(x)
  as_set(x) = Set([x,])
  inp_set = map(as_set ∘ as_expr, info.inp)
  create_with_shape = obj->map(_->obj(), info.inp)

  θs = info.θs
  function map_if_in(f, keys, collection_dst)
    for k in keys
      for (set, dst) in zip(inp_set, collection_dst)
        k ∈ set && f(k, dst)
      end
    end
    collection_dst
  end
  function match_assigns(collection_src)
    collection_dst = create_with_shape(Dict)
    map_if_in(keys(collection_src), collection_dst) do k, dst
      dst[k] = collection_src[k]
      pop!(θs, k)
    end
  end
  info.assigns_by_portn = match_assigns(info.assignments)
  info.specials_by_portn = match_assigns(info.specials)
  info.unassigns_by_portn = create_with_shape(Set)
  map_if_in(θs, info.unassigns_by_portn) do θ, dst
    push!(dst, θ)
  end
end

length_of(info::Arrows.ConstraintInfo, idx) = info.inp[idx] |> as_expr |> length

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

function generate_function(context::Dict, moniker)
  M = Module()
  for (k,v) in context
         eval(M, :($k = $v))
  end
  eval(M, moniker)
end

function generate_gather(indexed_elements, shape)
  generate_arrangement_arrow(indexed_elements, shape,
                              GatherNdArrow(),
                              :gather_wire)
end

function generate_scatter(indexed_elements, shape)
  generate_arrangement_arrow(indexed_elements, shape,
                              ScatterNdArrow(),
                              :scatter_wire)
end

function generate_arrangement_arrow(indexed_elements, shape, arr, name)
  carr = CompArrow(gensym(name), 1, 1)
  add = (arr)-> add_sub_arr!(carr, arr)
  indices = extract_indices(indexed_elements)
  sarr_indices = indices |> SourceArrow |> add
  sarr_shape = shape |> SourceArrow |> add
  sarr = arr |> add
  (sarr_indices, 1) ⥅ (sarr, 2)
  (sarr_shape, 1) ⥅ (sarr, 3)
  (carr, 1) ⥅ (sarr, 1)
  (sarr, 1) ⥅ (carr, 1)
  carr
end

factor_indices(v, indices::Set = Set()) = v
function factor_indices(v::Expr, indices::Set = Set())
  if v.head == :ref
    sub_expr, index = v.args
    push!(indices, index)
    factor_indices(sub_expr, indices)
  else
    args = map(v.args) do arg
            factor_indices(arg, indices)
          end
    Expr(v.head, args...)
  end
end

function extract_computation_blocks(assigns)
  function process_expr(v)
    indices = Set()
    expr = factor_indices(v, indices)
    @assert length(indices) < 2
    if length(indices) > 0
      v = Expr(:ref, expr, pop!(indices))
    end
    v, expr
  end
  by_block = DefaultDict(Vector)
  for (dst,src) in assigns
    (dst, _) = process_expr(dst)
    (src, expr_src) = process_expr(src)
    push!(by_block[expr_src], (dst, src))
  end
  by_block
end

function is_arrayed_port(info::ConstraintInfo, idx)
  ! isa(info.inp[idx] |> as_expr, Symbol)
end

function name(info::ConstraintInfo, idx)
  value = info.inp[idx] |> as_expr
  expr =  is_arrayed_port(info, idx) ? first(value) : value
  factor_indices(expr)
end

## TODO: what happens with the `else` statement?
function create_first_step_of_connection(info)
  function add_sport(arr, idx)
    sarr = add_sub_arr!(info.master_carr, arr)
    key = name(info, idx)
    info.names_to_inital_sarr[key] = sarr
    newport = link_to_parent!(▹(sarr, 1))
    info.is_θ_by_portn[idx] && addprop!(θp, newport)
    base_nm = Symbol(key, :_in)
    nm = uniquename(base_nm, name.(⬧(info.master_carr)))
    setprop!(Name(nm), props(newport))
  end
  for (idx, unassign) in enumerate(info.unassigns_by_portn)
    if length(unassign) > 0
      inner_connector = if is_arrayed_port(info, idx)
        pairs = Vector()
        values = collect(unassign)
        for (id_, dst) in enumerate(sort(values, by=extract_index))
          push!(pairs, (dst, id_))
        end
        create_inner_connector(info, pairs,  idx)
      else
        IdentityArrow()
      end
      add_sport(inner_connector, idx)
    elseif !info.is_θ_by_portn[idx]
      add_sport(IdentityArrow(), idx)
    end
  end
end


function create_inner_special_connector(info::ConstraintInfo,
                                pairs, idx,
                                variables,
                                moniker)
  inputs = map(x->x[2], pairs)
  outputs = map(x->x[1], pairs)
  full_expr = first(outputs)
  name_ = name(info, idx)
  expr = factor_indices(full_expr)
  function compute_arrow_special(carr, gather)
    c = CompArrow(gensym(:special), 1, 1)
    sport = generate_function(Dict([name_ => ▹(c, 1)]),
                      expr)
    sport ⥅ (c, 1)
    inv_c = Arrows.invert(c)
    sarr = add_sub_arr!(carr, inv_c)
    gather ⥅ (sarr, 1)
    ◃(sarr, 1)
  end
  actual_name = name(info, idx)
  pairs = zip(outputs, inputs)
  create_inner_connector_private(info,
          compute_arrow_special,
          pairs, idx,
          variables,
          moniker)
end

function create_inner_connector(info::ConstraintInfo,
                                pairs, idx,
                                variables,
                                moniker)
  f = (carr, g) -> g
  create_inner_connector_private(info,
                                  f,
                                  pairs, idx,
                                  variables,
                                  moniker)
end

function create_inner_connector(info::ConstraintInfo, pairs, idx)
  inputs = map(x->x[2], pairs)
  outputs = map(x->x[1], pairs)
  shape = tuple(length_of(info, idx))
  gather = generate_gather(inputs, size(inputs))
  scatter = generate_scatter(outputs, shape)
  gather >> scatter
end

function create_inner_connector_private(info::ConstraintInfo,
                  middle_arr_creator,
                  pairs, idx,
                  variables,
                  moniker)
  n = length(variables)
  inputs = map(x->x[2], pairs)
  outputs = map(x->x[1], pairs)
  carr = CompArrow(gensym(:inner_connector), n, 1)
  sarr = add_sub_arr!(info.master_carr, carr)
  g = generate_gather(inputs, size(inputs))
  shape = tuple(length_of(info, idx))
  s = generate_scatter(outputs, shape)
  scatter_sarr = add_sub_arr!(carr, s)
  context = Dict()
  for (idx, v) in enumerate(variables)
    (sarr_for_variable(info, v),1) ⥅ (sarr, idx)
    g_sarr = add_sub_arr!(carr, g)
    (carr, idx) ⥅ (g_sarr, 1)
    context[v] = ◃(g_sarr, 1)
  end
  sport = generate_function(context, moniker)
  middle = middle_arr_creator(carr, sport)
  middle ⥅ (scatter_sarr,1)
  (scatter_sarr,1) ⥅ (carr, 1)
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

function sarr_for_variable(info::ConstraintInfo, moniker::Symbol)
  if moniker ∈ keys(info.names_to_inital_sarr)
    info.names_to_inital_sarr[moniker]
  else
    warn("Variable $(moniker) was used but it's not wired")
    throw(DomainError)
  end
end

function create_special_assignment_graph_for(info::ConstraintInfo,
                                              sarr::SubArrow,
                                              idx)
  assigns = info.specials_by_portn[idx]

  if length(assigns) == 0
    return sarr
  end
  input_outputs = map(values(assigns)) do assignment
    (assignment.dst, assignment.src)
  end
  by_block = extract_computation_blocks(input_outputs)
  moniker = name(info, idx)
  connector_arr = CompArrow(gensym(:connector),
                    (length ∘ keys)(by_block) + 1,
                    1)
  connector_sarr = add_sub_arr!(info.master_carr, connector_arr)
  (sarr, 1) ⥅ (connector_sarr, 1)

  last_sport = ▹(connector_arr, 1)
  for (input_id, (block, pairs)) in enumerate(by_block)
    sarr = create_inner_special_connector(info, pairs, idx,
                                          extract_variables(block),
                                          block)
    (sarr, 1) ⥅ (connector_sarr, input_id + 1)
    last_sport = last_sport +  ▹(connector_arr, input_id + 1)
  end

  last_sport ⥅ (connector_arr, 1)
  connector_sarr
end

function create_assignment_graph_for(info::ConstraintInfo, idx)
  assigns = info.assigns_by_portn[idx]
  by_block = extract_computation_blocks(assigns)
  moniker = name(info, idx)
  has_initializer = haskey(info.names_to_inital_sarr, moniker)
  connector_arr = CompArrow(gensym(:connector),
                    (length ∘ keys)(by_block) + (has_initializer ? 1 :0),
                    1)
  connector_sarr = add_sub_arr!(info.master_carr, connector_arr)

  if has_initializer
    initial_sarr = sarr_for_variable(info, moniker)
    ◃(initial_sarr, 1) ⥅ (connector_sarr, n▸(connector_sarr))
  end

  if !is_arrayed_port(info, idx)
    if has_initializer
      ▹(connector_arr, n▸(connector_arr)) ⥅ (connector_arr, 1)
    end
    #TODO handle equations with scalars
    warn("equations with scalars are not handled")
    return connector_sarr
  end

  connectors = Vector()
  input_id = 0
  for (block, pairs) in by_block
    input_id += 1
    sarr = create_inner_connector(info, pairs, idx,
                                    extract_variables(block),
                                    block)
    push!(connectors, ▹(connector_arr, input_id))
    (sarr, 1) ⥅ (connector_sarr, input_id)
  end

  @assert n▸(connector_arr) > 0
  if length(connectors) > 0
    sport = first(connectors)
    foreach(connectors[2:end]) do c
      sport = sport + c
    end
    sport = has_initializer ? ▹(connector_arr, n▸(connector_arr)) + sport : sport
  else
    sport = ▹(connector_arr, n▸(connector_arr))
  end
  sport ⥅ (connector_arr, 1)
  connector_sarr
end

function finish_parameter_wiring(info, sarr, idx)
  vals = info.inp[idx] |> as_expr
  if isa(vals, Array)
    shape = SourceArrow(size(vals))
    sarr_shape = add_sub_arr!(info.master_carr, shape)
    sarr_reshape = add_sub_arr!(info.master_carr, ReshapeArrow())
    (sarr, 1) ⥅ (sarr_reshape, 1)
    (sarr_shape, 1) ⥅ (sarr_reshape, 2)
    outp = ◃(sarr_reshape, 1)
  else
    outp = ◃(sarr, 1)
  end
  nm = name(info, idx)
  prps = deepcopy(props(outp))
  setprop!(Name(nm), prps)
  outp ⥅ add_port!(info.master_carr, prps)
end


"""solve constraints on inputs to `carr`
It will return a tuple with a `CompArrow` (the wirer), and information regarding
the solving process.
Use `inv_c << wirer` to connect the wirer to the actual inverse `Arrow`"""
function solve(carr::CompArrow, initprops = SprtAbValues())
  info = constraints(carr, initprops)
  (compute_assigns_by_portn ∘ find_assignments)(info)
  info.master_carr = CompArrow(gensym(:solver_θ))
  create_first_step_of_connection(info)
  n = length(info.inp)
  foreach(1:n) do idx
    sarr = create_assignment_graph_for(info, idx)
    sarr = create_special_assignment_graph_for(info, sarr, idx)
    finish_parameter_wiring(info, sarr, idx)
  end
  info.master_carr, info
end
