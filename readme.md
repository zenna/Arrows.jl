Smooth Arrows
=============

Smooth Arrows are a representation of differentiable programs based on the [Arrow formalism](Arrows) from functional programming.  Their intended use is for learning and probabilistic inference.

[![Build Status](https://travis-ci.org/zenna/Arrows.jl.svg?branch=master)](https://travis-ci.org/zenna/Arrows.jl)

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
a = Arrows.lift(Arrows.sin1dfunc)
b = Arrows.compose(a,a)
c = Arrows.encapsulate(b)
stacked = Arrows.stack(c,c)
d = Arrows.multiplex(c,c)
e = Arrows.first(Arrows.lift(Arrows.cos1dfunc))
f = d >>> e
```
