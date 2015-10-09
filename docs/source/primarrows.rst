Primitive Arrows
================

.. _binary

plus1 :: Arrow [A], [A] -> [A]
plus2 :: Arrow [A, B], [A, B] -> [A, B]
plus3 :: Arrow [A, B, C], [A, B, C] -> [A, B, C]

minus1 :: Arrow{(A, A), (B)}
minus1 :: Arrow{(A, A), (B)}

concat :: Arrow [A] [B] -> [C] | C = A + B}

.. _distribute

.. function:: distribute :: Arrow{(A,),(B, C) | A = B + C}

Distribute Splits Returns uniformly distributed random variable between a and b
