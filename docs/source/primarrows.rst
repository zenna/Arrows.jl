Primitive Arrows
================

.. _pointwise:

Pointwise
---------

Arrows has support for common mathematical binary functions.
These functions are defined pointwise, so that adding two vectors results in a vector of the same size with each element the sum of the arguments.
Arrows supports `add,sub,mul,div,truediv,floordiv`, and for each arrow has an arrow up to a given dimensionality, e.g.:

.. function:: add1 :: Arrow [A], [A] -> [A]
.. function:: add2 :: Arrow [A, B], [A, B] -> [A, B]
.. function:: add3 :: Arrow [A, B, C], [A, B, C] -> [A, B, C]

.. function:: sub1 :: Arrow{(A, A), (B)}

concat :: Arrow [A] [B] -> [C] | C = A + B}

Linear Algebra
--------------

.. function:: dot :: Arrow [A], [A] -> [1]
inner product of vectors (without complex conjugation).

Arrow Sets
----------
.. _distribute:

.. function:: distribute :: Arrow{(A,),(B, C) | A = B + C}

Distribute Splits Returns uniformly distributed random variable between a and b
