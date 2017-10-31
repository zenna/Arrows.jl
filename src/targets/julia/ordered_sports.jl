import Base: Iterators


"Return the order in which the values of `carr` are assigned"
order_of_assigment(carr::Arrow, ::Set{CompArrow}) = []

"Return the order in which the values of `carr` are assigned"
function order_of_assigment(carr::CompArrow)
  order_of_assigment(carr, Set{CompArrow}())
end

"Return the order in which the values of `carr` are assigned"
function order_of_assigment(carr::CompArrow, seen::Set{CompArrow})
  push!(seen, carr)
  assigns = Vector{SrcValue}()
  function add_to_assigns(value)
    if value ∉ assigns
      push!(assigns, value)
    end
  end
  function f(sarr::SubArrow, args)
    out = out_values(sarr)
    foreach(add_to_assigns, in_values(sarr))
    foreach(add_to_assigns, out)
    map(name, out)
  end

  inputs = map(name, in_values(sub_arrow(carr)))
  interpret(f, carr, inputs)
  answer = Vector{Vector{SrcValue}}()
  to_arrow = deref ∘ sub_arrow ∘ src
  for value in assigns
    prev = to_arrow(value)
    if prev ∉ seen
      ordered = order_of_assigment(to_arrow(value), seen)
      if !isempty(ordered)
        push!(answer, ordered)
      end
    end
    push!(answer, [value,])
  end
  collect(Iterators.flatten(answer))
end

function parent_value(port::Port{CompArrow}, ::SrcValue)
  (SrcValue ∘ sub_port)(port)
end

function parent_value(::Port, default::SrcValue)
  default
end

"Return the order in which the values of `carr` are computed"
function order_values(carr::CompArrow)
  assigments = order_of_assigment(carr)
  order = Dict{SrcValue, Int}()
  idx = 1
  for value in assigments
    sport = src(value)
    p_value = parent_value(deref(sport), value)
    if p_value ∈ keys(order)
      order[value] = order[p_value]
    else
      order[value] = idx
      idx += 1
    end
  end
  order
end

"""Given a `CompArrow` and a `Vecotr{SubPort}`, return the order in which the
  elements of the vector are computed"""
function order_sports(carr::CompArrow, sports::Vector{SubPort})
  ordered_values = order_values(carr)
  pairs = Vector{Pair{Int, Int}}()
  for (idx, sport) in enumerate(sports)
    value = SrcValue(sport)
    position = ordered_values[value]
    push!(pairs, idx=>position)
  end
  sorted_pairs = sort(pairs, by=x->x[2])
  map(first, sorted_pairs)
end
