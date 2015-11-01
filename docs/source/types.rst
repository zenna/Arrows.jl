Types
=====

A type corresponds to a set of values.
For instance the type `{10, 20}` refers to all matrices of 10 rows and 20 columns.
Types can be *parametrically  polymorphic*, which means the type of a value contains variables.
For instance: the type `{M, N}` is the set of matrices of `M` rows and `N` columns.
If `M` and `N` are both unconstrained, `{M, N}` is the set of all matrices.
Similarly, while `{M,M}` is the set of all square matrices.
Type parameters can also be constrained, hence the type `{m, n} | m > n` refers to the set of all matrices with more rows than columns.

There are three kinds of type:

- Scalar Types
- Array types
- Arrow types

Scalar Types
------------


Array Types
-----------

Arrays are homogeneious - they contain scalars all of the same type.
Arrays are not nested; there are no arrays of arrays.
The type of an array can be fixed or parameterised with respect to any combination of (i) the type of scalar it holds (ii) the number of dimensions it has (iii) its shape - the number of elements in each dimension.
The example above `{M, N}` is fixed in dimensionality (2D) but parametric in shape.

We view parametric types as functions from parameters to types.
For instance the type `{m,n}` is a mapping t(m,n) -> {m,n}.
Conceptually we can imagine applying that types to values to get a concrete type, e.g. t(3,4) = {3, 4}.
Similarly we can partially apply types to values to yield types which are more concrete, but still parametric, e.g. t(3, _) = {3, n}.
In general, the type system is parameterised upon three stratified layer, each of which yields a type in the layer below.

The highest layer is array dimensionality.
For illustration, consider the type `{x_i for i = 1:n}`.
This is syntax for an array of type variables `{x1, x2, ..., xn}`, the number of which is itself variable (`n`).
A type which is parametric in dimension must provide properties: (1) an expression for the dimensionality.


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

We can treat a type which is parametric in dimensionality as
At the type level, a polymorhpic arrow is a binary relation on polymorphic types.
For instance {M, N} >> {M, M} is the set of all pairs matrices and all square matrix.

takes as input a polymorphic type and returns a polymorphic type with some constraints.  These constraints constrain the relation.
The composition of two polymorphic arrows is type consistent if there exists some selection of types at inp A, output A, inp B, output C
This is equivalent to saying that the join on types must be not empty.
Since this is a satisfiability problem, the type systm can be expressive as any satisfiability solver


Examples
--------

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

Constraints
-----------
Type constraints are assertions that should hold over any of the type variables.
The constraints on composite arrows are derived from the constraints on their primitive components.

What's *not* in a type
----------------------

The type system is both more restrictive (e.g. no nested arrays, no composite data types) than a normal language.
But it is also more expressive - these types contain more information (the shape of arrays, parametrically) than is normally specified in types.
However, notably missing is any information about the underlying values.
One could imagine having the type of a Sigmoid arrow containing the information that the output is always bound between 0 and 1.
This is not included because it would make type checking vastly more difficult and in some cases undecidable.

Type Checking
-------------
Type checking serves two purposes
1. To determine whether a program is consistent with respect to types
2. To determine valid values of nondeterministic values in ArrowSets
