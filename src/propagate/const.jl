

function const_content_propagator(sarrow::SubArrow, prop::Propagation)
  const_content_propagator(deref(sarrow), sarrow, prop)
end

function const_content_propagator(_::Arrow, sarrow::SubArrow, prop::Propagation)
#  same_content_propagator(sarrow, prop)
end

function const_content_propagator(_::PrimArrow, sarrow::SubArrow, prop::Propagation)
  seen = propagated_values(sarrow, prop)
  required = Set(in_values(sarrow))
  if intersect(Set(seen), required) == required
    if !isempty(required)
      any_value = first(required)
      content = prop.value_content[any_value]
      if content == known_const
        to_propagate = Set(out_values(sarrow))
        for value in to_propagate
          if value ∉ seen
            add_pending!(prop, value, content)
          end
        end
      end
    end
  end
end
