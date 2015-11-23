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


"""The most basic datatype in Arrows.jl is the multidimensional array, or simply array
The array in arrows should be thought of analogously to strings of bits in systems languages like c;
everything else in the language is just some structuring of computation around them.

Primitve Types
------------
Scalar types are the most primitive types:
IntX, FloatX, ComplexX, RationalX

Compound Types
--------------
Composite types are compositions of primitive types or composite types:

Array Types
-----------
Array types are multidimensional arrays of Primitive Or Composite Types.
Scalars are considered 0-dimensional arrays.
arrow types can be fixed or parameterised with respect to
- dimensionality of the array
- the element type

Arrow Types
-----------
Arrow types correspond an ordered list of input array types to an ordered
list of output array types.

The type system is stratified into layers.
This means that an arrow type can be parameterised in a number of ways
(shapes, elementtypes, values), there is only one arrow type, i.e. even though
it is parameterised in many ways in different layers there is still one predicate
which determines whether some set of inputs and outputs is valid.
Given that it seems that form a constraint perspective, what im calling stratification
is basically saying here are some variables, let's partition these into disjoint sets,
solve for one subset, substitute, then solve for the rest.
It's kind of different in the dimensionality case because the number of variables determined by the solution.
Is that special?

The following are in the relation +
[1.2], [2.2], [3.4]
[1, 1  [2, 3   [3, 4
 1, 1], 4, 3],  5, 4]

So if you give me a triple of these values, there is some test, with a unique answer
which will tell me whether that triple is in the relation.
The type system represents this set either exactly, or it may over approximate it.
One way the type system could represent this relation is to list out all the elements.
This would not be economoical in space, and may be impossible if the space is unbounded.
We can do much better if instead we use variables to implicitly define a space.
Constraints on these variables will give us more power to better approximate the space we want.

For instance we might have concat as
concat {A}, {B} >> {C}
which says that [1,2], [3,4], [1,2,3,4] is in the relation

It also says [1,2], [3,4], [1,2,3,4,5] is in the relation

We can restrict that by saying
concat :: {A}, {B} >> {C} | C == A + B

Now we have a type that represents a relation which more concretely represents the true relation.

Note that neither type restricts a whole class of bad values; bad in the sense they dont belong to the relation.

There are two things going on
- empirically, restriction of array shapes elimiates most common errors.
In other words, most primitive functions are defined all all inputs of a given size.
For instance + can take any two arrays if their shapes are identical.
The same is true for multiplication, negation, etc.
There are exceptions of course, like division; and these indeed are the cause of errors.

Back to the central problem.
When we use variables to represent a relation, these variables must correspond to some things and there must
be some mapping between that and the underlying set.
For instance the elemetype may be represented by an enumeration variable which ranges of Int, Float, etc.

The crux of the issue is this:

There are some relations that cannot be represented with a finite number of variables.

Thats not quite it.

First of we have to acknowledge the way we've defined this set.  It is parameterically.
Alternatively, we could have defined a function which mapped a value to whether its in the relation or not.
A predicatee.

Theres some list X and some list Y and forall x in X and y in Y x == y.

So the point is, for our given parameterisation, there's no wnay to define this set with a finite number of variables.
Our choices are then to choose a different parameterisation, e.g. one where we can reason about variable size arrays
and use quantificaiton, or split the type system.

We'll call a stratified parameteric model as one composed of a base logical formula L_1, and a finite sequence of functions (L,f_1,...,f_n)
We generate a base model L_1, m_1.
We evaluate L_2 = f_1(m_1), and generate a model for L_1, m_2.
We stop once we have generated a model for L_n.

- In general this might not terminate
- In our use case, it will terminate, because the number of solutions at each levels is bounded
- Also in general, it is not necesary to have an explicit mapping between the model at any intermediate stage and the relation.

- In our case, the base formula refers to Dimensionality
- The second cases refer to
Each model

Constraints
Stratifiation places limitations of the constraints that can be imposed.
In short, constraints cannot cross the levels.
In practice, for arrays, there are rarely constraints between dimensionality and shape.
This is in part because dimensionality is tightly linked to shape, its a function of it.
In other words, the constraints between the shape and the dimensionality are implicit in the function generator.
An ill formed function generator could for example, solve for dimension and get a value of 2, but return a shape type with 3 dimensions.
In essence this would be problematic because we use the dimensionality

What is the stratification.

L_0: Dimension parameters
f_0: Function that maps dimension model to something that is parametric in shape and value

- Can you treat the arrays of an arrow independently, no!
- Why do you have parametric types for variables but not values.
- Parametric types are used basically to define a set of functions and ensure one of them is valid using type checking.
- If you have a parametric
Viewed from another way we do have parametric values if you think of functions or arrows as values.
a parametric array would be a kind of nondeterministic values.
Basically there are two ways to define a nondeterministic value, by making its type parametric or by making its constructively nondeterminstic.

There could be a mechanism for nondeterminstic arrays, but what use would it have.

You could be liek partial(+, nondetermisticarray).  im not sure what the point would be, it would be possible, for sure.
It's not obvious.

either way, what do we need.  We
"""

"""
The type system is stratified.
- In a first order system, there are the following kinds of types. (i) Primitive Types (ii) ArrayTypes (iii) ArrowTypes.
- The type system is stratified.
- L_0 is parametric in elementtype
- L_1 is parametric in dimension
- L_2 is parametric in shape and value

- If element type is unsat then everything else is unsat.
- If dimension is unsat then everything else is unsat
- shape and value are a function of.

The restriction we might make is

nodes = [elementtype,dimension,shape,values]
arrows = [dimension->(shape,values)]
"""
