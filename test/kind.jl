# using Base.Test

t1 = Kinder.Parameter{Integer}(:t)
t2 = Kinder.CompositeParameter{Integer}(:(2t))
t12 = tuple(t1, t2)
fl = Kinder.FixedLenVarArray(t12)


xi = Kinder.IndexedParameter(:x)
n = Kinder.Parameter{Integer}(:n)
vl = Kinder.VarLenVarArray(n, xi)

a = Kinder.Parameter{Integer}(:a)
s = Kinder.ShapeParams{Real}(a, vl)

v = Kinder.`ValueParams`(a, fl)
c1 = Kinder.CompositeParameter{Bool}(:(2t > 3))
c2 = Kinder.CompositeParameter{Bool}(:((t + 1) > 5))


arrtyp = Kinder.ArrowType{1, 1}((s,), (v,), [c1, c2])
arrsettyp = Kinder.ArrowType{1, 1}((s,), (arrtyp,), [])

plustyp = @arrow [@shape([x_i for i = 1:n]) @shape([x_i for i = 1:n])] @shape([x_i for i = 1:n]
