using Arrows

## Construct A complex arrow using combinators
a = Arrows.lift(Arrows.sin1dfunc)
c = Arrows.compose(a,a)
stacked = Arrows.stack(c,c)
d = Arrows.multiplex(c,c)
e = Arrows.first(Arrows.lift(Arrows.cos1dfunc))
f = d >>> e
# imperative = Arrows.compile(Arrows.NamedArrow(:testf, f))
# o = imperative[1]
# convert(Expr, imperative)
# cppout = convert(Arrows.CppExpr, imperative)
# convert(Arrows.CppExpr, imperative.calls[1])
