Arrow Types
===========

Types serve two purposes.
First, they ensure that the arrows you attempt to construct are well-formed.
Second, types allow us to write very abstract code.
Here we will show what information is kept in a type and the syntax we use to describe them.

Arrow Types
-----------

The type of an arrow represents a set of possible concrete arrows.
An `ArrowType` contains the following information:

- The number of inputs and outputs of the arrow
- For each input and output the type of the array

.. function:: Arrow iptype1 ..., iptype_n -> optype1, ..., optype_m | constraint

Each exp iptype_i
Array Types
-----------
The type of an array (`ArrayType`) contains the following information

- The number of dimensions of an array
- An expression for the size of each dimension.  This expression may be a constant of a type variable.

.. function:: [dim_1, dim_2, ... dim_n]

Example
-------

Let's consider the concatenation arrow.
`ConcatArr`, similarly to the function concat, takes in two vectors of the same size, and returns a vector of the arguments concatenated.
It's type is written syntactically as follows:

.. function:: concat :: Arrow [A], [B] -> [A + B]


This means that concat is an arrow with two inputs
The inputs are both vectors which have a `A` and `B` numbers of elements respectively.
The output is vector which has `A + B` elements, as we expect.

We could have also written concat as follows:

.. function:: concat :: Arrow [A], [B] -> [C] | C = A + B

Here we have introduced a new variable `C` and added the constraint `C = A + B`.
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
