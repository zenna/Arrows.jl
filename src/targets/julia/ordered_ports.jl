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

function ordered_values(carr::CompArrow)
  assigments = order_of_assigment(carr)
  answer = Dict{Arrows.SrcValue, Int}()

  for (idx, value) in enumerate(assigments)
    sport = Arrows.src(value)
    p_value = parent_value(deref(sport), value)
    if p_value ∈ keys(answer)
      answer[value] = answer[p_value]
    else
      answer[value] = idx
    end
  end
  sort(collect(answer), by=x->x[2])
end
