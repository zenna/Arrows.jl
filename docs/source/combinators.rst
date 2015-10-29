Combinators
===========

The following is a list of the combinators currently supported in Arrows.
You can of course, in Julia, construct your own combinators from these primitives.
Note that all combinators are pure functions - they construct new arrows and leave their arguments unmodified.

This turns a pure function into an arrow

.. _compose:

Compose
-------

Wire outputs of `a` to inputs of `b`, i.e. a_out_1 --> b_in_1, a_out_2 --> b_in_1

.. code-block:: julia
  compose{I1, O1I2, O2}(a::Arrow{I1,O1I2}, b::Arrow{O1I2,O2})::Arrow{I1, O2}

.. code-block:: julia
  sinarr >>> cosarr >>> sqrtarr

.. _first:

First
-----

Takes two inputs side by side. The first one is modified using an arrow `a`, while the second is left unchanged.

.. _stack:

Stack
-----

Stack arrow `a` on top of arrow `b` into a new arrow `c`, i.e. union two composite arrows into the same arrow.
The inputs of `a` will be the first inputs of `c` and the outputs of `a` will be the first outputs of `c`.

.. code-block:: julia
  stack{I1, O1, I2, O2}(a::CompositeArrow{I1,O1}, b::CompositeArrow{I2,O2})
