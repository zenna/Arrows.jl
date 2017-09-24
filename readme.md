# Arrows.jl

[![Build Status](https://travis-ci.org/zenna/Arrows.jl.svg?branch=master)](https://travis-ci.org/zenna/Arrows.jl)

[![codecov.io](http://codecov.io/github/zenna/Arrows.jl/coverage.svg?branch=master)](http://codecov.io/github/zenna/Arrows.jl?branch=master)

Arrows.jl is an experimental library for learning and inference in Julia. It is:

- Relational
- Dependently typed

To do this, we build upon the formalism of [Arrows](https://en.wikibooks.org/wiki/Haskell/Understanding_arrows)

# Documentation

<!-- [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://zenna.github.io/Arrows.jl/stable) -->
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://zenna.github.io/Arrows.jl/latest)


## Installation

Arrows is currently highly experimental; explore at your own risk.  Arrows is not yet in the official Julia Package repository.
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
