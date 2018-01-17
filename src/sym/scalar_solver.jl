using NamedTuples

collect_symbols(::Any, seen = Set()) = seen
function collect_symbols(expr::Expr, seen=Set())
  foreach(expr.args[2:end]) do e
    collect_symbols(e, seen)
  end
  seen
end
function collect_symbols(sym::Symbol, seen = Set())
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
  inverted = Arrows.invert(carr, inv, sprtabvals)
  @assert num_ports(carr_original) == num_ports(inverted)
  inverted
end

#TODO: Compute this dynamically
valid_calls = Set([:(==), :⊻, :md2box, :inverse_md2box])
"find a variable to solve for, and compute the solution to that"
function solve_expression(expr, computed, arrows)
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

function solve_expressions(exprs)
  computed = Set{Symbol}()
  arrows = Dict{Symbol, Arrow}()
  foreach(exprs) do expr
    solve_expression(expr, computed, arrows)
  end
  arrows
end

function forward(expr)
  names = collect_symbols(expr)
  carr = generate_forward(names, expr)
  @NT(names = names, carr = carr, expr = expr)
end

function solve_to(variable, left, right)
  @assert isempty(setdiff(collect_calls(left.expr), valid_calls))
  @assert isempty(setdiff(collect_calls(right.expr), valid_calls))
  inv_right = partial_invert_to(right.carr, variable)
  portmap = Dict{Arrows.Port, Arrows.Port}([p1 => p2 for p1 in ◂(left.carr)
                                                     for p2 in ▸(inv_right)
                                                     if name(p1) == name(p2)])
  Arrows.compose(inv_right, left.carr, portmap)
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
