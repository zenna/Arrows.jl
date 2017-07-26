Arrow Sets
==========

Learning is typically framed as an optimisation over a set of functions.
This set is defined implicitly through parameters, e.g., weight matrices for a neural network.
Similarly, (probabilistic) inference methods search over, sample from, or measure sets of values of random variables.
Fundamental to both cases is the notion of *non-determinism*, i.e. a set of possibilities.

An arrow set (`ArrowSet`) represents a set of possible arrows.
Conceptually, arrow sets are extremely powerful for two reasons.
First, they wrap computation and parameters into a modular unit.
This module can be transplanted or replicated across the same or a different model in arbitrary ways, or nested within a more complex arrow set.
Second, they allow partial specification of code.
Building complex programs with different array dimensions and sizes often leads to complex code with tedious data reshaping, which is highly dependent on the data size.
Arrow sets abstract away from these details (and solve them using automated constraint solvers), making programming easier and modules more general.

Just as random-variables (i.e. pure functions) are used to represent sets of values in probability theory, we use normal arrows to represent an arrow set.
The first kind of arrow set is any arrow which maps a vector of real values to an arrow.
An `ArrowSet` is any arrow with the type:

.. code-block:: haskell

    as :: [P] >> (A >> B)

`as` is an arrow which takes as input a vector of `P` reals and returns an arrow.

The simplest arrow of this form that we can write is the constant ArrowSet.

.. code-block:: haskell

    constarrset :: [P] :> ([] >> [A])

Given an input vector `a`, `constarrset` returns an constant arrow which takes no input and returns a vector `a`.
Note that we've replaced the `>>` with `:>`; this is just for notational clarity.

Example
-------

Suppose we wanted to define a module which added which took in a 5 x 5 matrix and incremented each element by some amount.

.. code-block:: julia

    first(constarrset >>> repmat(5,5)) >>> lift(+)

Integer Vector Types
--------------------

Arrows.jl has a special type for known-length integer vectors.
These conform to the syntax:

.. code-block:: haskell

    ivec :: {A_1, ..., A_n}

A very important point is that the variables correspond to the *integer values* in the vector.
This is different from the `ArrayType` notation `[A_1, ..., A_n]` where the variables correspond to the dimension sizes.

.. code-block:: haskell

    distribute :: {I} :> [A] -> [B], [C] | A = B + C & I == B

`distribute` splits an input vector into two parts, it is kind of the inverse of concatenate.
Where it splits is non-deterministic, and hence distribute is an `ArrowSet` and not an `Arrow`.


ArrowSet De/Constructors
------------------------

There are a number of ways to convert between an ArrowSet and an Arrow:

.. code-block:: haskell

    reify :: ([P] :> [A] >> B) -> [P] -> ([A] >> [B])

.. _reify:

reify turns an ArrowSet into an Arrow.
It takes an ArrowSet of `P` parameters and a vector of `P` parameters and returns the corresponding `Arrow`.

.. _expose:

.. code-block:: haskell

    expose :: ([P] :> [A] >> [B]) -> [A, P] >> [B]

expose turns an ArrowSet into an Arrow by pulling out all the inputs of the Arrow.

.. _partial:

.. code-block:: haskell

    partial :: ([P1] :> [A] >> B) -> [P2] -> ([P1-P2] :> [A] >> B) | P2 < P1

partial returns an ArrowSet which requires fewer parameters by *baking in* some concrete set of parameters

ArrowSet Combinators
--------------------

.. _compose:

.. function:: >>> :: (ArrowSet [A] -> [B] [P1]) -> (ArrowSet [B] -> [C] [P2]) -> Arrow [P0] -> [P1 + p2] -> (ArrowSet [A] -> [C] [P0])

.. code-block:: haskell

    >>> :: ([P1] :> [A] >> [B]) -> ([P2] :> [B] >> [C]) -> ([P0] >> [P1 + P2]) -> ([P0] :> [A] >> [C])


Composition of ArrowSets is similar but slightly more complex than composition of normal Arrows.

Primitive Arrow Sets
--------------------
.. _distribute:

.. function:: distribute :: Arrow [A] -> [B], [C] | A = B + C}

Distribute Splits Returns uniformly distributed random variable between a and b

TODO
----

What I am trying to capture here is the idea of a set of arrows.
Moreover I want that set to be buildable constructively.
By constructively I mean the set should be defined by a computable procedure from some simpler
set to a more complex set.
This is in contrast to declaratively or implicitly.

- Should an arrowset be an arrow from a vector of values to an arrow or to anything.
A random variable in Sigma is a functiom from a euclidean box to any type T.
Why should we favour the arrow as the output.
Well 1. we're mostly interested in function learning. and an arrow is like a function.
2. We don;t necessarily need to preclude other output types, we're just saying this is what an arrowset is,
or a nondeteriminstic ararow.  i.e we need not delineate it technically but conceptually and with tooling.

- Can an arrow and an arrowset be used consistently.
If an arrowset is just a function, all the combinators are already well defined.
To get different behaviour we need eitehr different combinators or a different tpye of thing.
What kind of behaviour do we want

1. To be able to plug an arrow into a new place regardless of its parameters

For instance there may be some section for my neural network architecture that takes a vector of 3 inputs
I should be able to take a parameter set of some number of inputs and plug that in

I could tolerate changing the combinators, although its not idela

One thing we need to do when we plug in an arrow set is specify how to handle the parameters.

There seem to be two conflictin goals

1. is consistency withinthe arrow type system, say everything is jsut an arrow.

2 is to say consistency between usage.

first' :: a >> (b >> c)
first' a = arr \x -> first a x

i.e. first is an arrow which takes some vector input applies it to the arrowset to get an arrow,
then applies first to that arrow

# can this be done with just combinators? Surely

first' a = a >>> lift first

>>> :: (a >> (b >> c)) -> (e >> (c >> d))
>>>' a b = (a *** b) >>> (lift >>>)

So really the question comes down to whether I want to
- Describe these arrowsets using new combinators
- Describe these as a new kind of arrow and redefine the existing combinators
