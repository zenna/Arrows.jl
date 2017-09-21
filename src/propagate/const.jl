# Functions required for constant propagation.
# Current implementation has the following invariants:
#   - The default behavior is to no propagate over an arrow
#   - If *all* the in_values of a `PrimArrow` are constant, then its output
#     are also constants
#   - The output of any `SourceArrow` is a constant.


"""Function that selects the propagator according to the subtype
    of `deref(sarrow)`"""
function const_propagator!(sarrow::SubArrow, prop::Propagation)
  const_propagator!(deref(sarrow), sarrow, prop)
end

"Default `const_propagator`: do nothing"
function const_propagator!(_::Arrow,
                                  sarrow::SubArrow,
                                  prop::Propagation)
end

"""`const_propagator` for `PrimArrow`: propagate only when all incoming values
  are const"""
function const_propagator!(_::PrimArrow,
                                  sarrow::SubArrow,
                                  prop::Propagation)
  seen = propagated_values(sarrow, prop)
  required = Set(in_values(sarrow))
  if intersect(Set(seen), required) == required
    if !isempty(required)
      any_value = first(required)
      content = prop.value_content[any_value]
      if content == known_const
        values = Set(out_values(sarrow))
        propagate_known_const!(prop, seen, values)
      end
    end
  end
end

"""`const_propagator` for `SourceArrow`: all outputs are constants"""
function const_propagator!(_::SourceArrow,
                                sarrow::SubArrow,
                                prop::Propagation)
  seen = Set(keys(prop.value_content))
  to_propagate = Set(out_values(sarrow))
  propagate_known_const!(prop, seen, values)
end


"helper function to propagate `known_const` in a given set"
function propagate_known_const!(prop::Propagation,
                                seen,
                                values::Set{SrcValue})
  for value in values
    if value ∉ seen
      add_pending!(prop, value, known_const)
    end
  end
end