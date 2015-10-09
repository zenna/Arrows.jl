using Arrows

## Construct A complex arrow using combinators
a = Arrows.lift(Arrows.sin1dfunc)
c = Arrows.compose(a,a)
stacked = Arrows.stack(c,c)
d = Arrows.multiplex(c,c)
e = Arrows.first(Arrows.lift(Arrows.cos1dfunc))
f = d >>> e
