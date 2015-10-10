Arrow Sets
==========

Learning is typically framed as an optimisation over a set of functions.
This set is defined implicitly through parameters, e.g., weight matrices for a neural network.
Similarly, (probabilistic) inference methods search over, sample from, or measure sets of values of random variables.
Fundamental to both cases is the notion of *non-determinism*, i.e. a set of possibilities.

An `ArrowSet` represents a set of possible Arrows.
Just as random-variables (i.e. pure functions) are used to represent sets of values in probability theory, we use normal arrows to represent an ArrowSet.
There are two kinds of ArrowSet, the first is any arrow which maps a vector of real values to an arrow.
An ArrowSet is any Arrow with the type:

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

-
