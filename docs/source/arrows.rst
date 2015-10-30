Arrows
======

Arrows represent computations that are ‘function-like’, in that they take inputs and produce output.
However, arrows can be composed in more exotic ways than simple function composition.
Building complex arrows involves wiring simpler arrows together, somewhat like an electronic circuit.
Hence, arrows bear resemblance to data-flow languages, hardware description languages, and artificial neural networks.
The main advantages of arrows over these other program representations are that it provides more powerful means of abstraction and modularity, and a natural way to reason about (continously) time varying input.
Other than in Arrows.jl have been used almost solely within the Haskell programming language for functional reactive programming, where they are formalised as the a type class `Arrow`.

Suppose we wanted to describe a computation which took in a vector of real numbers, and an arrow which took in a vector of real numbers, squared them all, split the matrix in half and

.. code-block:: julia

    lift(sqr) >>> clone >>> (sum &&&

The type of the Arrow

.. code-block:: haskell

    a :: [A] >> [1], [1]
