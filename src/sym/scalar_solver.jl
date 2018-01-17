

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
  for p in in_sub_ports(carr)
    context[name(deref(p)).name] = p
  end
  p = Arrows.generate_function(context, expr)
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
  Arrows.invert(carr, inv, sprtabvals)
end


function compute_inverse_constraint(expr)
  valid_calls = Set([:(==), :⊻, :md2box, :inverse_md2box])
  @assert isempty(setdiff(collect_calls(expr), valid_calls))
  left, right = expr.args[2:end]
  names_right = collect_symbols(right)
  names_left = collect_symbols(left)
  carr_right = generate_forward(names_right, right)
  inv_right = partial_invert_to(carr_right, pop!(names_right))
  carr_left = generate_forward(names_left, left)
  portmap = Dict{Arrows.Port, Arrows.Port}([p1 => p2 for p1 in ◂(carr_left)
                                                     for p2 in ▸(inv_right)
                                                     if name(p1) == name(p2)])
  Arrows.compose(inv_right, carr_left, portmap)
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
