
"Axiomatic specification of correctness of an abstract data type"
abstract Specification
printers(Specification)

"""
An algebraic structure refers to a set (called carrier set or underlying set)
with one or more finitary operations defined on it that satisfies a list of axioms
"""
immutable AbstractDataType
  adt::AbstractNonDetArray
  typs::Vector{ArrowType} # Or uninterpreted arrows?
  spec::Specification     # What kind of thing is this? I have it
end

printers(AbstractDataType)
function string(adt::AbstractDataType)
  interfacestrings = join([string(typ) for typ in adt.typs], "\n")
  """
  AbstractDataType $(x.adt)
  $interfacestrings
  """
  # $(string(x.spec))
end

"""Specification formed by set of (conjunctive) equalities.
Equivalent to a *variety* in unviersal algebra"""
immutable EquationalSpec <: Specification
  equalities::Set{Arrow} # Or uninterpreted arrows?
end

what kidn of thing are these equaltieis.
well they are a set of equations.  One way I can represent equations are as functions
from values to true/false.

if we take the push >>> pop example.
What this is saying is that if you give me an implementatin of push and of pop
then for any s, and i, that application applied to the substituted arrow should yield true.

First things first, we need to replace equality with something smooth.
But probably it's better to not do it here.
Leave the equalities as they are and replace them in teh smoothing process.


But what kind of thing is the LHS.
One idea is that its a combinator that creates arrows.
Another idea is that iit is itself an arrow

string(es::EquationalSpec) = join([string(eq) for eq in es.equalities])

"""Make a executable specification of an adt `a` wrt to implementation `impl`.
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
