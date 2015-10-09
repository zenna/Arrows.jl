Arrow Sets
==========

Typically, problems of learning are formalised as optimisations over a set of functions.
This set is defined implicitly through some set of parameters, e.g. weight matrices for a neural network.
Similarly, problems of (probabilistic) inference search over, sampling from, or measure sets of values of random variables.
Fundamental to both cases is a set of possibilities, i.e. non-determinism.

An `ArrowSet` represents a set of possible Arrows.
Just as random-variables (i.e. pure functions) are used to represent sets of values in probability theory, we use normal arrows to represent an ArrowSet.
The benefit of this approach (as opposed to say )

It is formalised as a function from a vector of real values to an arrow.
This formalism is constructive, in the sense we can

Types
-----



ArrowSet Combinators
--------------------

.. _reify:

.. function:: reify :: (ArrowSet [A] -> [B] [P]) -> [P] -> Arrow [A] -> [B]

reify turns an ArrowSet into an Arrow.
It takes an ArrowSet of `P` parameters and a vector of `P` parameters and returns the corresponding `Arrow`.

.. _expose:

.. function:: expose :: (ArrowSet [A] -> [B] [P]) -> Arrow [A, P] -> [B]

expose turns an ArrowSet into an Arrow.

.. _partial:

.. function:: reify :: (ArrowSet [A] -> [B] [P]) -> [P] -> Arrow [A] -> [B]

partial returns a smaller .

ArrowSet Combinators
--------------------

.. _compose:

.. function:: >>> :: (ArrowSet [A] -> [B] [P1]) -> (ArrowSet [B] -> [C] [P2]) -> Arrow [P0] -> [P1 + p2] -> (ArrowSet [A] -> [C] [P0])

.. code-block:: haskell

    >>> :: ([A] >> [B] [P1]) -> ([B] >> [C] [P2]) -> ([P0] >> [P1 + P2]) -> ([A] >> [C] [P0])


Composition of ArrowSets is similar but slightly more complex than composition of normal Arrows.

Primitive Arrow Sets
--------------------
.. _distribute:

.. function:: distribute :: Arrow [A] -> [B], [C] | A = B + C}

Distribute Splits Returns uniformly distributed random variable between a and b
