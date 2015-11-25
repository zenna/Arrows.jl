
"Axiomatic specification of correctness of an abstract data type"
abstract Specification

"""
An algebraic structure refers to a set (called carrier set or underlying set)
with one or more finitary operations defined on it that satisfies a list of axioms
"""
immutable AbstractDataType
  typs::Vector{ArrowType}
  spec::Specification
end

"""Specification formed by set of (conjunctive) equalities.
Equivalent to a *variety* in unviersal algebra"""
immutable EquationalSpec <: Specification
  equalities::Set{Arrow}
end

"""Make a executable specification of an adt `a` wrt to implementation ` impl`.
Constructs an arrow that takes as input (universally quantified) variables and
outputs (measure of) whether spec is satisfied on that input.
If the implementation is composed of arrow sets, the spec will be an arrowset"""
function executable_spec(a::AbstractDataType, imp::Arrow)
  error("unimplemented")
end

## Concrete Data Type
## ==================

"""
Concrete Data Types is an implementation of an abstract data type
- a data type which is semantically distinguished from its representation. e.g.
  we can represent an interval with a 2 element vector but they are NOT the same thing.
  Particularly, operations which apply to 2elem vecs do not apply to intervals and
  vice versa (this is debatable).
- Is a set of arrows which allow one to (i) construct an element in the data type (ii) transform it
- Is an implementation of an abstract data type."""
immutable ConcreteDataType
  name::Symbol
  data::NonDetArray
  interfaces::Vector{Arrow}
end

"An implementation, i.e. instance of an sbtract data type"
immutable Instance
  cdt::ConcreteDataType
  adt::AbstractDataType
end

"Nondeterminstic array which is parametric"
immutable AbstractNonDetArray <: NonDetArray
  name::Symbol
end

## TODO
# - Do piping and application for UninterpretedArrow
# - Figure out concrete data types
