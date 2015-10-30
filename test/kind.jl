# using Base.Test

t1 = kind.Parameter{Integer}(:t)
t2 = kind.TransformedParameter{Integer}(:(2t))
t12 = tuple(t1, t2)
fl = kind.FixedLenVarArray(t12)


xi = kind.IndexedParameter(:x)
n = kind.Parameter{Integer}(:n)
vl = kind.VarLenVarArray(n, xi)

a = kind.Parameter{Integer}(:a)
s = kind.ShapeParams{Real}(a, vl)

v = kind.`ValueParams`(a, fl)
c1 = kind.TransformedParameter{Bool}(:(2t > 3))
c2 = kind.TransformedParameter{Bool}(:((t + 1) > 5))


arrtyp = kind.ArrowType{1, 1}((s,), (v,), [c1, c2])
arrsettyp = kind.ArrowType{1, 1}((s,), (arrtyp,), [])

plustyp = @arrow [@shape([x_i for i = 1:n]) @shape([x_i for i = 1:n])] @shape([x_i for i = 1:n]
