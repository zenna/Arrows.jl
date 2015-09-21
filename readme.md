Smooth Arrows
=============

Smooth Arrows are a representation of differentiable programs based on the [Arrow formalism](Arrows) from functional programming.  Their intended use is for learning and probabilistic inference.

## Tutorial

Arrows are a bit like functions, except we can wire their input and outputs in more interesting ways than simple function composition.

Let's work through it by example.

For most differentiable functions there is an equivalent lifted arrow, e.g. for `cos`, there is `cosarr`.

```julia
julia> typeof(plusarr)
Arrows.PrimArrow{2,1}
``
This means cosarr is a primitive arrow which takes 2 input and 1 output.  As you might expect `typeof(cosarr) = PrimArrow{1,1}`.

More complex arrows are made by combining simpler arrows.  We can __wire__ these two arrows together using `>>>`.

```julia
plusarr >>> cosarr
```



TODO
====

- Do Layout
- Compile to theanofollow
- Compile to stan
