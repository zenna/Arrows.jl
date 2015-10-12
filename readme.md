Smooth Arrows
=============

Arrows.jl is a non-deterministic, differentiable programming environment with refinement types.
The premise is that it is useful to view deep neural networks as programs  with those of funcitonal programming languages.
namely that they can learn multiple, increasingly abstract representations of data, and can be effectively learned using gradient method.s since they are differentiable.  -  with the benefits of modern programming languages - recursion, modularity, higher-orderness, types.
To do this, we build upon the formalism of [Arrows](https://en.wikibooks.org/wiki/Haskell/Understanding_arrows).
Arrows leans heavily on the [theano](http://deeplearning.net/software/theano/) (as a compilation target) and the [Z3 interactive theorem prover](https://github.com/Z3Prover/z3) for type-checking.


[![Build Status](https://travis-ci.org/zenna/Arrows.jl.svg?branch=master)](https://travis-ci.org/zenna/Arrows.jl)

## Installation

Arrows requires depends on the following:

- Python
- theano
- Z3

Arrows is built on top of Julia but not yet in the official Julia Package repository.
You can still easily install it from a Julia repl with:

```julia
Pkg.clone("https://github.com/zenna/Arrows.jl.git")
```

Arrows is then loaded with:

```julia
using Arrows
```
## Usage

[Read the documentation](http://arrowsjl.readthedocs.org/en/latest/) or check out the quick start below

## Quick Start

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
