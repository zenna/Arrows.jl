## Named Arrow
## ===========
"""An arrow with a symbolic name.

  Named arrows enhance composition/reus, since they can be used in another arrow
  without duplication."""
immutable NamedArrow{I,O} <: Arrow{I,O}
  name::Symbol
  arrow::CompositeArrow{I, O}
end
