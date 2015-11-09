## Init Arrow
## ==========
"""A `stateful` arrow who outputs a value at time 0 and thereafter outputs its input,
  i.e. it behaves like an identity arrow.
  This arrow is used with the `loop` combinator to model recursion.
"""
immutable InitArrow{I} <: PrimArrow{I,I}
  initval::Tuple
end
