# Arrows.jl

[![Build Status](https://travis-ci.org/zenna/Arrows.jl.svg?branch=master)](https://travis-ci.org/zenna/Arrows.jl)

[![codecov.io](http://codecov.io/github/zenna/Arrows.jl/coverage.svg?branch=master)](http://codecov.io/github/zenna/Arrows.jl?branch=master)


Arrows.jl is a non-deterministic, differentiable programming environment with refinement types.

To do this, we build upon the formalism of [Arrows](https://en.wikibooks.org/wiki/Haskell/Understanding_arrows).
Arrows leans heavily on the [theano](http://deeplearning.net/software/theano/) (as a compilation target) and the [Z3 interactive theorem prover](https://github.com/Z3Prover/z3) for type-checking.


[![Build Status](https://travis-ci.org/zenna/Arrows.jl.svg?branch=master)](https://travis-ci.org/zenna/Arrows.jl)

## Installation

Arrows is a Julia package but not yet in the official Julia Package repository.
You can still easily install it from a Julia repl with:

```julia
Pkg.clone("https://github.com/zenna/Arrows.jl.git")
```

Arrows is then loaded with:

```julia
using Arrows
```

## Quick Start

Arrows are a bit like functions, except we can wire their input and outputs in more interesting ways than simple function composition.

Let's work through it by example.

```julia
arr = AddArrow() >> SinArrow()
arr(1.0, 2.0)
```
