import Base: Iterators

#TODO: remove the Arrows.

ordered_values(carr::Arrow, ::Set{Arrows.CompArrow}) = []

function ordered_values1(carr::CompArrow)
  ordered_values(carr, Set{Arrows.CompArrow}())
end

function ordered_values(carr::CompArrow, seen::Set{Arrows.CompArrow})
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
      ordered = ordered_values(to_arrow(value), seen)
      if !isempty(ordered)
        push!(answer, ordered)
      end
    end
    push!(answer, [value,])
  end
  collect(Iterators.flatten(answer))
end
