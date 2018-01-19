using NamedTuples
import DataStructures: DefaultDict, counter

collect_symbols(::Any, seen = counter(Symbol)) = seen
function collect_symbols(expr::Expr, seen = counter(Symbol))
  foreach(expr.args[2:end]) do e
    collect_symbols(e, seen)
  end
  seen
end
function collect_symbols(sym::Symbol, seen = counter(Symbol))
  push!(seen, sym)
  seen
end


collect_calls(e::Any) = Set()
function collect_calls(e::Expr)
  if e.head == :call
    rest = union(map(collect_calls, e.args[2:end])...)
    push!(rest, e.args[1])
  else
    union(map(collect_calls, e.args)...)
  end
end

function generate_forward(names, expr)
  carr = CompArrow(gensym(:forward), [x for x in names], Array{Symbol,1}())
  context = Dict()
  context[:inverse_md2box] = Arrows.inverse_md2box
  context[:md2box] = Arrows.inverse_md2box
  for p ∈ in_sub_ports(carr)
    context[name(deref(p)).name] = p
  end
  p = Arrows.generate_function(context, expr)
  ## When the expression is a single variable, we need to add
  ## the identity function
  if isa(expr, Symbol)
    p = Arrows.compose!(vcat(p), IdentityArrow())[1]
  end
  newport = link_to_parent!(p)
  Arrows.setprop!(Arrows.Name(:forward_z), Arrows.props(newport))
  carr
end

partial_invert(arr, sarr, abvals::IdAbValues) = inv(arr, sarr, abvals)
function partial_invert(arr::AbsArrow, sarr, abvals::IdAbValues)
  unary_inv(arr, const_in(arr, abvals), IdentityArrow)
end


"Given a forward function and a target, compute its partial inverse"
function partial_invert_to(carr_original, target)
  carr = deepcopy(carr_original)
  sprtabvals = SprtAbValues()
  for sport in ▹(carr)
    if (sport |> deref |> name).name != target
      sprtabvals[sport] = Dict([:isconst=>true])
      sport |> deref |> Arrows.make_out_port!
    end
  end
  @show sprtabvals
  inverted = Arrows.invert(carr, partial_invert, sprtabvals)
  if num_ports(carr_original) != num_ports(inverted)
    @show carr_original
    @show inverted
    @grab inverted
    @show target
  end
  @assert num_ports(carr_original) == num_ports(inverted)
  inverted
end

#TODO: Compute this dynamically
valid_calls = Set([:(==), :⊻, :md2box, :inverse_md2box, :-, :abs])
"find a variable to solve for, and compute the solution to that"
function solve_expression_naive(expr, computed, arrows)
  if !isempty(setdiff(collect_calls(expr), valid_calls))
    warn("cannot solve constraint: $(expr)")
    return
  end
  names = collect_symbols(expr)
  for variable ∈ setdiff(names, computed)
    String(variable)[1] == 'z' && continue
    ## TODO: n might appear many times in the expression.
    left, right = map(forward, expr.args[2:end])
    if variable ∈ left.names && variable ∈ right.names
      @warn "skipping: $expr"
      continue
    end
    if variable ∈ left.names
      left, right = right, left
    end
    arr = solve_to(variable, left, right)
    push!(computed, variable)
    return arrows[variable] = arr
  end
  warn("cannot solve constraint: $(expr)")
end

function solve_expressions_naive(exprs)
  computed = Set{Symbol}()
  arrows = Dict{Symbol, Arrow}()
  foreach(exprs) do expr
    solve_expression_naive(expr, computed, arrows)
  end
  arrows
end

function forward(expr)
  names = collect_symbols(expr)
  carr = generate_forward(names |> keys, expr)
  @NT(names = names, carr = carr, expr = expr)
end

function solve_to(variable, left, right)
  @assert isempty(setdiff(collect_calls(left.expr), valid_calls))
  @assert isempty(setdiff(collect_calls(right.expr), valid_calls))
  @show right.expr
  inv_right = partial_invert_to(right.carr, variable)
  portmap = Dict{Arrows.Port, Arrows.Port}([p1 => p2 for p1 in ◂(left.carr)
                                                     for p2 in ▸(inv_right)
                                                     if name(p1) == name(p2)])
  Arrows.compose(inv_right, left.carr, portmap)
end

function build_mappings(exprs)
  var_to_expr = DefaultDict(Set)
  expr_to_var = DefaultDict(Set)
  for expr ∈ exprs
    !isempty(setdiff(collect_calls(expr), valid_calls)) && continue
    variables = expr |> collect_symbols |> keys
    for variable ∈ variables
      String(variable)[1] == 'z' && continue
      push!(var_to_expr[variable], expr)
      push!(expr_to_var[expr], variable)
    end
  end
  var_to_expr, expr_to_var
end

"""This function creates a bipartite graph. Nodes on the left are
variables and nodes on the right are expressions. An edge means that
a variable is present in the expression.
We choose expressions with a single edge, and use the variable that
this edge represents. Then we remove the edges associated with that variable.
When no expression contains a single edge, we arbitrarily choose the variable
with the largest amount of edges, and continue"""
function matching(v_to_e, e_to_v)
  v_to_e, e_to_v = map(deepcopy, (v_to_e, e_to_v))
  answer = Dict()
  run = true
  function remove_var(var, expr)
    for other ∈ v_to_e[var]
      var ∈ e_to_v[other] && pop!(e_to_v[other], var)
    end
    pop!(v_to_e, var)
  end
  while run
    run = false
    for (expr,vars) ∈ e_to_v
      if length(vars) == 1
        var = pop!(vars)
        @assert var ∉ keys(answer)
        left, right = map(forward, expr.args[2:end])
        names = merge(left.names, right.names)
        if names[var] != 1
          # There are things we cannot solve:
          # When a variable appears multiple times in a constraint
          # So, if we find that we should be able to solve a variable from a
          # constraint, we skipt that.
          pop!(e_to_v, expr)
          continue
        end
        run = true
        answer[var] = (left, right)
        remove_var(var, expr)
      end
    end
    if !run && length(v_to_e) > 0
      var = sort(collect(v_to_e), by=x->length(x[2]))[end][1]
      answer[var] = nothing
      remove_var(var, nothing)
      run = true
    end
  end
  answer, v_to_e, e_to_v
end

"solve expressions using bipartite matching"
function solve_expressions(exprs)
  var_to_expr, expr_to_var = build_mappings(exprs)
  matchs, var_to_expr, expr_to_var = matching(var_to_expr, expr_to_var)
  arrows = []
  for (var, pair) ∈ matchs
    isa(pair, Void) && continue
    left, right = pair
    if var ∈ keys(left.names)
      left, right = right, left
    end
    push!(arrows, solve_to(var, left, right))
  end
  arrows
end

"create a wirer for the solved constraints"
function create_wirer(arrows)
  carr = CompArrow(gensym(:wirer), 0, 0)
  sports = Dict()
  actual_name = x->(x |> deref |> name).name
  sarrs = map(arrows) do arr
    sarr = Arrows.add_sub_arr!(carr, arr)
    sport = ◃(sarr, 1)
    sports[sport |> actual_name] = sport
    Arrows.link_to_parent!(sport)
    sarr
  end
  foreach(sarrs) do sarr
    foreach(▹(sarr)) do dst
      var = dst |> actual_name
      if var ∉ keys(sports)
        sports[var] = Arrows.add_port_like!(carr, dst |> deref) |> sub_port
      end
      sports[var] ⥅ dst
    end
  end
  carr
end

"Compose the constraints solver with the inverse"
function wire(inverse::CompArrow, solver::CompArrow)
  wired = CompArrow(gensym(:wired), 0, 0)
  sarr = add_sub_arr!(wired, inverse)
  swirer = add_sub_arr!(wired, solver)
  actual_name = (name ∘ deref)
  wirer_in = Dict([actual_name(p)=> p for p ∈ ▹(swirer)])
  wirer_out = Dict([actual_name(p)=> p for p ∈ ◃(swirer)])
  for sport ∈ ▹(sarr)
    if actual_name(sport) ∈ keys(wirer_out)
      wirer_out[actual_name(sport)] ⥅ sport
    else
      newport = Arrows.link_to_parent!(sport)
      if name(newport) ∈ keys(wirer_in)
        newport ⥅ wirer_in[name(newport)]
      end
    end
  end
  Arrows.link_to_parent!(swirer, Arrows.is_in_port ∧ Arrows.loose)
  Arrows.link_to_parent!(sarr, Arrows.is_out_port ∧ Arrows.loose)
  wired
end

includes_ifelse(expr) = false
function includes_ifelse(expr::Expr)
  if expr.head == :call
    if expr.args[1] == :ifelse
      if any(includes_ifelse, expr.args)
        warn("cannot compute nested if statements")
        return false
      end
      return true
    end
  end
  return any(includes_ifelse, expr.args)
end


extract_ifelse(base_expr) = nothing
function extract_ifelse(expr::Expr)
  if expr.head == :call && expr.args[1] == :ifelse
    return Dict([:condition => expr.args[2],
               :true_ => expr.args[3],
               :else_ => expr.args[4]])
  end
  filtered = filter(x->x != nothing,
                    map(extract_ifelse, expr.args))
  length(filtered) > 0 ? filtered[1] : nothing
end

function process_ifelse(expr)
  replace_ifelse(expr, other) = expr
  function replace_ifelse(expr::Expr, other)
    if expr.head == :call && expr.args[1] == :ifelse
      return other
    end
    Expr(expr.head, [replace_ifelse(e, other) for e in expr.args]...)
  end
  ifelse_ = extract_ifelse(expr)
  ifelse_[:true_] = replace_ifelse(expr, ifelse_[:true_])
  ifelse_[:else_] = replace_ifelse(expr, ifelse_[:else_])
  ifelse_
end


"Solve constraints and create a composed arrows witht the solution"
function solve_md2(carr::CompArrow, initprops = SprtAbValues())
  info = Arrows.constraints(carr, initprops)
  wirer = info.exprs |> solve_expressions |> create_wirer
  wire(carr, wirer)
end

function rewrite_exprs(exprs, basic_context, wirer)
  context = Dict{Symbol, Any}()
  for (k,v) ∈ basic_context
    context[k] = v
  end
  info = Arrows.ConstraintInfo()
  Arrows.symbol_in_ports(wirer, info, SprtAbValues())
  outs = interpret(Arrows.sym_interpret, wirer, info.inp)
  for (idx, port) in enumerate(name.(◂(wirer)))
    context[port.name] = outs[idx] |> Arrows.as_expr
  end
  rewrite(x::Symbol) = x ∈ keys(context) ? context[x] : x
  rewrite(x::Expr) = Expr(x.head, map(rewrite, x.args)...)
  rewrite(x) = x
  map(rewrite, exprs)
end

function solve_with_ifelse(unsatisfied, context, wirer)
  # TODO rewrite expressions to be expressed as a function of previously defined
  # independent variables
  exprs = []
  for expr ∈ unsatisfied
    left, right = expr.args[2:end]
    if includes_ifelse(left)
      ifelse_ = extract_ifelse(left)
      cond = ifelse_[:condition]
      if cond ∉ keys(context)
        continue
      end
      left = context[cond] ? ifelse_[:true_] : ifelse_[:else_]
    end
    if includes_ifelse(right)
      ifelse_ = extract_ifelse(right)
      cond = ifelse_[:condition]
      if cond ∉ keys(context)
        continue
      end
      right = context[cond] ? ifelse_[:true_] : ifelse_[:else_]
    end
    push!(exprs, Expr(:call, :(==), left, right))
  end
  # TODO: add arrows for the things we have in the context
  rewrite_exprs(exprs, context, wirer) |> Arrows.solve_expressions
end

# left, right = expr_4.args[2:end]
# names_4 = collect_symbols(right)
# c = CompArrow(:bla, [x for x in names_4], Array{Symbol,1}())
# context = Dict()
# context[:inverse_md2box] = Arrows.inverse_md2box
# for p in in_sub_ports(c)
#   context[name(deref(p)).name] = p
# end
#
# p = Arrows.generate_function(context, right)
# link_to_parent!(p)
# c |> Arrows.compile
#
# sprtabvals = SprtAbValues()
# sprtabvals[context[:θxor91]] = Dict([:isconst=>true])
# Arrows.invert(c, inv, sprtabvals)
#
#
#
# bla = Arrows.wrap(XorArrow())
# sprtabvals = SprtAbValues()
# sprtabvals[in_sub_port(bla, 1)] = Dict([:isconst=>true])
# Arrows.invert(bla, inv, sprtabvals)
