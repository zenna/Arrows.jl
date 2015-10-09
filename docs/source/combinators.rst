Combinators
===========

The following is a list of the combinators currently supported in Arrows.
You can of course, in Julia, construct your own combinators from these primitives.
Note that all combinators are pure functions - they construct new arrows and leave their arguments unmodified.



.. _lift:

Lift
----

This turns a pure function into an arrow

.. _compose:

Compose
-------

This combinator writes the output of an arrow `a` to the input of an arrow `b`

.. math::

  f(x; a, b) = \frac{1}{b - a}, \quad a \le x \le b

.. function:: compose{I1, O1I2, O2}(a::Arrow{I1,O1I2}, b::Arrow{O1I2,O2}) -> Arrow{I1, O2}

    Returns uniformly distributed random variable between a and b

.. code-block:: julia

  compose(lift(sqrt), lift(inc))    # sqrt ⋅ inc]
  sqrt >>> inc                      # >>> can be used infix and compose can does automatic lifting


.. _first:

First
-----

Takes two inputs side by side. The first one is modified using an arrow `a`, while the second is left unchanged.
