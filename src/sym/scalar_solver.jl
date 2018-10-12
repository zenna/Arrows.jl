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

partial_invert(arr, sarr, abvals::IdAbVals) = inv(arr, sarr, abvals)
function partial_invert(arr::AbsArrow, sarr, abvals::IdAbVals)
  unary_inv(arr, const_in(arr, abvals), IdentityArrow)
end


"Given a forward function and a target, compute its partial inverse"
function partial_invert_to(carr_original, target)
  carr = deepcopy(carr_original)
  sprtabvals = SprtAbVals()
  for sport in ▹(carr)
    if (sport |> deref |> name).name != target
      sprtabvals[sport] = Dict([:isconst=>true])
      sport |> deref |> Arrows.make_out_port!
    end
  end
  inverted = Arrows.invert(carr, partial_invert, sprtabvals)
  inverted
end

#TODO: Compute this dynamically
valid_calls = Set([:(==), :⊻, :md2box, :inverse_md2box, :-, :abs, :/])


function forward(expr)
  names = collect_symbols(expr)
  carr = generate_forward(names |> keys, expr)
  (names = names, carr = carr, expr = expr)
end

"create a wirer for the solved constraints"
function create_wirer(arrows)
  carr = CompArrow(gensym(:wirer), 0, 0)
  sports = Dict()
  sarrs = map(arrows) do arr
    sarr = Arrows.add_sub_arr!(carr, arr)
    sport = ◃(sarr, 1)
    sports[sport |> port_sym_name] = sport
    Arrows.link_to_parent!(sport)
    sarr
  end
  foreach(sarrs) do sarr
    foreach(▹(sarr)) do dst
      var = dst |> port_sym_name
      if var ∉ keys(sports)
        sports[var] = Arrows.add_port_like!(carr, dst |> deref) |> sub_port
      end
      sports[var] ⥅ dst
    end
  end
  carr
end

function ensure_out_link_to_parent(sprt)
  arr = parent(sprt)
  n = sprt |> deref |> name
  for p in ◂(arr)
    if name(p) == n
      return
    end
  end
  link_to_parent!(sprt)
end

function compose_by_name(solvers)
  wired = CompArrow(gensym(:wired), 0, 0)
  add = x->add_sub_arr!(wired, x)
  sarrs = map(add, solvers)
  in_, out_ = Dict(), Dict()
  for sarr ∈ sarrs
    for sprt ∈ ⬨(sarr)
      d = is_in_port(sprt) ? in_ : out_
      d[port_sym_name(sprt)] = sprt
    end
  end
  for sarr ∈ sarrs
    for sprt ∈ ▹(sarr)
      moniker = sprt |> port_sym_name
      if moniker ∉ keys(out_)
        out_[moniker] = add_port_like!(wired, sprt |> deref) |> sub_port
      end
      out_[moniker] ⥅ sprt
    end
  end
  for sarr in sarrs
    Arrows.link_to_parent!(sarr, Arrows.is_out_port ∧ Arrows.loose)
    Arrows.link_to_parent!(sarr, Arrows.is_out_port ∧ Arrows.loose)
  end
  wired
end


"Compose the constraints solver with the inverse"
function wire(inverse::CompArrow, solvers)
  compose_by_name([inverse, solvers...])
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
function solve_scalar(carr::CompArrow,
                   context = Dict{Symbol, Any}(),
                   initprops = SprtAbVals())
  info = Arrows.constraints(carr, initprops)
  non_parameters = map(port_sym_name, filter(!is(θp), ▸(carr)))
  non_parameters = Set{Symbol}(non_parameters)
  exprs = rewrite_exprs(info.exprs, context)
  arrs = solve_graph(exprs, non_parameters)
  wirer = arrs |> create_wirer
  wire(carr, [wirer,]), wirer
end


function find_unsolved_constraints(carr, inv_carr, wirer, context)
  function add_from_output!(arr, inputs)
    for (p, o) ∈ zip(◂(arr), arr(inputs...))
      context[port_sym_name(p)] = o
    end
  end
  ## Populate the context with the output of the forward on
  ## a fixed input: 1:16
  add_from_output!(carr, 1:16)

  # Create inputs to arrow if not in context
  add_if_absent = p -> get!(context, port_sym_name(p), 0x19)
  inputs = map(add_if_absent, ▸(wirer))
  add_from_output!(wirer, inputs)
  foreach(add_if_absent, ▸(inv_carr))
  solved, unsolved = Array{Any,1}(), Array{Any,1}()
  info = Arrows.constraints(inv_carr, SprtAbVals())
  for expr ∈ info.exprs
    set = try
      Arrows.generate_function(context, expr) ? solved : unsolved
    catch y
      warn("expression $(expr) failed to run with exception $y")
      unsolved
    end
    push!(set, expr)
  end
  solved, unsolved, context
end

function rewrite_exprs(exprs, context)
  rewrite(x::Symbol) = x ∈ keys(context) ? context[x] : x
  rewrite(x::Expr) = Expr(x.head, map(rewrite, x.args)...)
  rewrite(x) = x
  map(rewrite, exprs)
end

function rewrite_exprs(exprs, basic_context, wirer)
  context = Dict{Symbol, Any}()
  for (k,v) ∈ basic_context
    context[k] = v
  end
  info = Arrows.ConstraintInfo()
  Arrows.symbol_in_ports(wirer, info, SprtAbVals())
  outs = interpret(Arrows.sym_interpret, wirer, info.inp)
  for (idx, port) in enumerate(name.(◂(wirer)))
    context[port.name] = outs[idx] |> Arrows.as_expr
  end
  rewrite_exprs(exprs, context)
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
