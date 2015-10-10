Arrows.jl's documentation
=========================

Arrows.jl is a differentiable programming environment implemented in Julia.
The goal is to combine the benefits of deep neural networks - namely, that they are differentiable, -  with the benefits of modern programming languages - recursion, modularity, higher-orderness, types.
To do this, we build upon the formalism of Arrows.

Arrows is built on top of Julia but not yet in the official Julia Package repository.
You can still easily install it from a Julia repl with:

.. code-block:: julia

  Pkg.clone("https://github.com/zenna/Arrows.jl.git")

Arrows is then loaded with

.. code-block:: julia

  using Arrows

Contents:

.. toctree::
   :maxdepth: 2

   starting
   modeling
   arrows
   arrowsets
   primarrows
   combinators
   library

   license


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
