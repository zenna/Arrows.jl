Inversion
---------

Many problems of inverse and learning can be viewed as inverse problems.
Inverse problems are when you have a model

Arrows can be inverted, when possible.
For every invertible arrow (e.g. `incarr`), there is an inverse arrow.

Inverse arrows are created through the `inv` combinator, e.g.

inv(inc(5))

If an arrow is composed of purely invertible functions it can be trivially inverted.
This is achieved, again, using `inv`

...


Inverting non invertible functions
----------------------------------

Unfortunately most interesting models (and hence the arrows that represent them) are not invertible.
Even a simple arrow like addition `+`.
In this case, `inv` produces a parameterised arrow.
