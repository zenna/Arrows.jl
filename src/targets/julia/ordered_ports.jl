import Base: Iterators

#TODO: remove the Arrows.

order_of_assigment(carr::Arrow, ::Set{Arrows.CompArrow}) = []

function order_of_assigment(carr::CompArrow)
  order_of_assigment(carr, Set{Arrows.CompArrow}())
end

function order_of_assigment(carr::CompArrow, seen::Set{Arrows.CompArrow})
  push!(seen, carr)
  assigns = Vector{Arrows.SrcValue}()
  function f(sarr::SubArrow, args)
    outnames = map(name, Arrows.out_values(sarr))
    for value in Arrows.out_values(sarr)
      if value ∉ assigns
        push!(assigns, value)
      end
    end
    outnames
  end

  inputs = map(name, Arrows.in_values(sub_arrow(carr)))
  interpret(f, carr, inputs)
  answer = Vector{Vector{Arrows.SrcValue}}()
  to_arrow = Arrows.deref ∘ Arrows.sub_arrow ∘ Arrows.src
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

function parent_value{T}(port::Arrows.Port{Arrows.CompArrow, T},
                        ::Arrows.SrcValue)
  (Arrows.SrcValue ∘ sub_port)(port)
end

function parent_value{T}(::Arrows.Port{Arrows.Arrow, T},
                        default::Arrows.SrcValue)
  default
end

function order_values(carr::CompArrow)
  assigments = order_of_assigment(carr)
  order = Dict{Arrows.SrcValue, Int}()
  idx = 1
  for value in assigments
    sport = Arrows.src(value)
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

function order_sub_ports(carr::CompArrow, sports::Vector{SubPort})
  ordered_values = order_values(carr)
  pairs = Vector{Pair{Int, Int}}()
  for (idx, sport) in enumerate(sports)
    value = Arrows.SrcValue(sport)
    position = ordered_values[value]
    push!(pairs, idx=>position)
  end
  sorted_pairs = sort(pairs, by=x->x[2])
  map(first, pairs)
end
