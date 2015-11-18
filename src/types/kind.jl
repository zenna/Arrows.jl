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

## Kind: types of type
## ===================
"All permissible types"
abstract Kind
printers(Kind)

## Array Type : Represent n-dimensional arrays
## ===========================================
"Represents a set of arrays through some parameterisation"
abstract ArrayType <: Kind

"Is an array type of a fixed number of dimensions"
isfixeddims(at::ArrayType) = isa(ndims(at), Integer)

# "Scalar represents a scalar value, e.g. an integer, or a real"
# immutable Scalar{T} <: ArrayType #FIXME: Should this be ArrayType?
#   val::ParameterExpr{T}
# end
#
# ndims(s::Scalar) = 0
# string(s::Scalar) = string(s.val)

"""Class of arrays parameterised by dimensionality.
A parameter that represents the dimensionality of an array"""
immutable ElementParam <: ArrayType
  value::ParameterExpr{DataType} #FIXME, get a better type than datatype
end

string(e::ElementParam) = string(e.value)

"""Class of arrays parameterised by dimensionality.
A parameter that represents the dimensionality of an array"""
immutable DimParam <: ArrayType
  value::ParameterExpr{Integer}
end

string(e::DimParam) = string(e.value)

"""Class of arrays parameterised by their shape.
s:ShapedParameterisedArrayType denotes `s` is an array which elements of type `T`
Elements in `s` correspond to the dimension sizes of s"""
immutable ShapeParams <: ArrayType
  dimtypes::VarArray                  # e.g. [1, 2t, p]
end

"Number of dimensions of the array this shape parameter represents"
ndims(a::ShapeParams) = length(a.dimtypes)
string(a::ShapeParams) = string("{", string(a.dimtypes),"}")

"""Class of Arrays parameterised by values
"""
immutable ValueParams <: ArrayType
  values::VarArray
end

"Number of dimensions of the array this ValueParams represents"
ndims(a::ValueParams) = ndims(a.values)
length(a::ValueParams) = length(a.values)
string(a::ValueParams) = string("[", string(a.values),"]")

## Arrow Extentions
## ================
abstract ArrowType <: Kind

"Class of arrows parameterised by dimensionality of individual scalars"
immutable ArrowParam{I, O, D} <: Kind
  inptypes::Tuple{Vararg{D}}
  outtypes::Tuple{Vararg{D}}
  constraints::ConstraintSet
  function ArrowParam(
      inptypes::Tuple{Vararg{D}},
      outtypes::Tuple{Vararg{D}},
      constraints::ConstraintSet)
    @assert length(inptypes) == I && length(outtypes) == O
    new{I,O, D}(inptypes, outtypes, constraints)
  end
end

string(d::ArrowParam) = string(join([string(t) for t in d.inptypes], ", "), " >> ",
                            join([string(t) for t in d.outtypes]))

"Return a new dimension type with variables substituted,"
function substitute{I, O, D}(d::ArrowParam{I, O, D}, varmap::Dict) #FIXME, make types tighter
  newinptypes = [substitute(t, varmap) for t in d.inptypes]
  newouttypes = [substitute(t, varmap) for t in d.outtypes]
  # FIXME: add constraints
  ArrowParam{I, O, D}(tuple(newinptypes...), tuple(newouttypes...))
end

"Set of unique dimensionality parameters"
function parameters(d::ArrowParam)
  paramset = Set{Parameter{Integer}}()
  # FIXME: add constraints, d.constraints
  for dtype in vcat(d.inptypes..., d.outtypes...)
    @show dtype
    union!(paramset, parameters(dtype))
  end
  paramset
end


## Stratified Type
## ===============
#
# "Type is one where more concrete parameterisations are generated from more abstract ones"
# immutable StratifiedType <: Kind
#   ...
# end
#
# What are we actually trying to do, we're trying to generate a partial arrow.
# This means we need to update the type.
# In order to update the type we need some mechanism.  Just the simplest thing is,
# change the values of dimtype and the values of arraytype.
#
# But in general this won't work for really stratifeid types, where we actually do code gen.
# Also I haven't even handled scalar types properly.

## ArrowType : Represent types of arrow
## ====================================


"This is an explicit arrow type; I'm breaking everything"
immutable ExplicitArrowType{I, O} <: ArrowType
  elemtype::ArrowParam{I, O, ElementParam}
  dimtype::ArrowParam{I, O, DimParam}
  shapetype::ArrowParam{I, O, ShapeParams}
  valuetype::ArrowParam{I, O, ValueParams}
  constraints::ConstraintSet
end


# """an arrow type represents the type at the input and type of output
# These types could be array types, or other arrows types."""
# immutable ArrowType{I, O} <: Kind
#   dimtype::ArrowParam{I,O}
#   inptypes::Tuple{Vararg{Kind}}
#   outtypes::Tuple{Vararg{Kind}}
#   constraints::ConstraintSet
#
#   "Construct DimTypes from Arrowtypes if not given"
#   function ArrowType(
#       dimtype::DimType{I,O},
#       inptypes::Tuple{Vararg{Kind}},
#       outtypes::Tuple{Vararg{Kind}},
#       constraints::ConstraintSet)
#     @assert length(inptypes) == I
#     @assert length(outtypes) == O
#     new{I,O}(dimtype, inptypes, outtypes, constraints)
#   end
#   function ArrowType(
#     dimtype::DimType{I,O},
#     inptypes::Tuple{Vararg{Kind}},
#     outtypes::Tuple{Vararg{Kind}})
#     new{I, O}(dimtype, inptypes, outtypes, ConstraintSet())
#   end
# end

function string{I,O}(x::ExplicitArrowType{I,O})
  pstrings = [string(a) for a in [x.elemtype, x.dimtype, x.shapetype, x.valuetype]]
  join(pstrings, "\n")
  # constraints = string(join(map(string, x.constraints), " & "))
end
