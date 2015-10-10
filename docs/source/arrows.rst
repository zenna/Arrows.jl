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


Arrow Types
-----------

Arrows are typed, which serves two purposes.
First, types ensure that arrows are well-formed; since our type system is both less expressive and more powerful than general programming languages, almost all well-typed programs can be executed withour error.
Second, especially when combined with `ArrowSets`, types allow us to write very abstract, modular programs.

An `ArrowType` represents a set of possible concrete arrows; it contains the following information:

- The number of inputs and outputs of the arrow
- For each input and output the type of the array

Arrow Types conform to the following syntax:

.. code-block:: haskell

    a :: I_1, ..., I_n >> B_1, ..., B_m | C

Where`I_i` and `I_o` are respectively input and output *array types*, and `C` is a type constraint.

Array Types
-----------
In Arrows.jl arrows take as input and return as output real valued arrays.
The type of an array (`ArrayType`) contains the following information:

- The number of dimensions of an array
- An expression for the size of each dimension: a constant, a type variable, or a linear function of the two.
- Any constraints on type variables

A `D` dimensional array adheres to the following type syntax

.. code-block:: haskell

    ndarray :: [D_1, ..., D_n | C ]

Example
-------

Let's consider the concatenation arrow.
`ConcatArr` concatenates two vectors.
Its type is written syntactically as follows:

.. code-block:: haskell

    concatarr :: [A], [B] >> [A + B]

This means that concat is an arrow with two inputs, which are vectors of size `A` and `B` respectively.
The output is vector which has `A + B` elements, as we expect.

We could have also written concat as follows:

.. code-block:: haskell

    concatarr :: [A], [B] >> [C] | C = A + B

Here we have introduced a new type variable `C` and added the constraint `C = A + B`.
Constraints go after the symbol `|`

.. _pointwise:

Constraints
-----------
Type constraints are assertions that should hold over any of the type variables.
The constraints on composite arrows are derived from the constraints on their primitive components.

What's Not in the type
----------------------
Note that these types contain more information than is normally specified in types.
However, notably missing is any information about the underlying values.
One could imagine having the type of a Sigmoid arrow containing the information that the output is always bound between 0 and 1.
This is not included because it would make type checking vastly more difficult and in some cases undecidable.

TODO
----

- Examples of using combinators
- Type variables are integer typed
-
