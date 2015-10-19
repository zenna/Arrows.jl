## ArrowSet
## =======

"""An ArrowSet represents a set of possible Arrows.

  It is formalised as a function from a vector of real values to an arrow.
  This formalism is constructive, in the sense we can
"""
immutable ArrowSet{I,O} <: Arrow{I,O}
end

# "A constant arrow. Takes no input (formally maps any input to same output)."
# immutable contingoustArrow{O} <: Arrow{0,O}
# end
#
# ConstArrow(x::Vector) = lift(constant(x))
#
#
# ## ArrowSet
# ## =======
#
# # Parameters are special in smooth arrows
# - An ArrowSet represents a set of possible arrows
# - The simplest ArrowSet is a set of constant arrowsets
# - It's formalised as an  paramater is an arrow of type Arrow{1,1} of type (A,B)
# -
#
# """An ArrowSet represents a set of possible Arrows.
#
#   It is formalised as a function from a vector of real values to an arrow.
#   This formalism is constructive, in the sense we can
# """
# immutable ArrowSet{I,O} <: Arrow{I,O}
# end
#
# "Construct Constant ArrowSet"
# function ArrowSet(a::Arrow{1,1})
#   # TypeCheck
#
# end
#
# >>>(a::ArrowSet, b::ArrowSet, c::Arrow)
#
# ""
# function compose{I1, O1I2, O2}(a::ArrowSet{I1,O1I2}, b::ArrowSet{O1I2,O2}, c::CompositeArrow{1,1})
# end
#
# ""
# ## We need some functionality which will take a vector and construct an arrow of that type
# ## Creating Constant Arrow Types
# jump(x::ArrowSet{I,O})
#
# - What kind of thing should an arrowset be? A simple function? a new typeclass, or just a type of arrow.
#
# If its just a type of arrow, then it cant be used with existing arrows, the types wont match.
# e.g.
# Arrow{RealVec(10), Arrow{A,B}} >> ....
# is not going to match
#
# Option 2. Make it just a function.
#
# It should be a new type class.
