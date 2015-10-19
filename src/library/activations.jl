## activation functions
## ====================

# # The idea is that sigmoid is in a way type polymorphic,
# # it can operate on arrays of any size, but it always returns a single array of`
# @arrow sigmoid "sigmoid(x) = 1/1+exp(-x)"           # add name to help
# @arrow sigmoid :: [...n] >> [...n]                  #
# @arrow sigmoid :: [T] >> [T]
# @arrow sigmoid :: [T1, T2] >> [T1, T2]
# @arrow sigmoid :: [T1, T2, T3] >> [T1, T2, T3]
# @arrow sigmoid = minus >> exp >> inc >> reciprocal
#
# # I could devise a reasonable notation for something like that, but I don't know how to reason about it automatically
#
# ## There are different levels of abstract ness
# ## 1. sigmoid only has one definition
# ## 2. Sigmoid can have multiple definitions, but each one must be concrete
# ## 3. Sigmoid can be defined for arbitrary length,
#
# b
#
# ## Units
# ## =====


# Units are arrow sets which take a vector of parameters, a vector of inputs and
# return a single scalar output
#
# "A single sigmoid unit"
# @arrow sigmoid_as :: [P] :> [T] >> Real                # This type signature should constraint the definition

# params = lift(identity)
#
# sigmoid_unit = first(param) >>> (dot >>> sigmoid)

## Different ideas for parameters

"""
Different ideas for parameters

1. Nothing - params as extra inputs to a function

In other words, in this scenario the parameters hold no special place formally.

This is unsatisfying because for the examples we are interested in there is a
distinct notion of paramters.  We should treat them differently, rather than just
keeping this idea in our heads.

In addition it removes modularity. If you give me some unit, how can I use it?
I don't know which are the parameters and which aren't.

2. Parameters are arrosets, functions from parameters to arrows.

P >> (A >> B)

This makes it very clear what the parameters are `P`, and what the function inputs are `A`

But what about when the thing im trying to learn is not a

- How do we generate an arrow that has parameters 'built-inm, like a clojure.
Using functiosn we would do something like

f(x) = y -> y + x

With arrows:

lift x -> lift constant x

Will give us an arrow which constructs a constant Arrow
- We lifted closures to get this capability
- Isi t actually what we want?.

Here's a question, given just the arrow combinators and lifted primitives, can we construct
an arrow which takes in a value and returns an arrow with that integer as the constant argument
to +




"""

# "parameterised unit rom an activation unit "
# gen_unit(activation_unit::Arrow{1,1}) Arrow([P] :> [T] >> Real, first(param) >> (dot >> activation_unit))
#
# ## Layers
# ## ======
#
# # Layers are arrow sets which take a vector of parameters, a vector of inputs and
# # return a single scalar output
#
# ## Sigmoid Layer
#
# "Fully connected sigmoid_layer"
# @arrow fc_sigmoid_layer [P] :> [M] >> [N]
# matrix_param >> dot >> sigmoid
#
# - Need the ability to add further type constraints to input or output,
# - but not necessarily to all arrows of that type.
#
# @arrow [A,A], [A] >> [A]
# dot
# clone(100) >>* sigmoid_as split
# ## Example
