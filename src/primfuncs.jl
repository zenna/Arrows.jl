## Primitive Tensor Functions
## ==========================

clone(x::Vector) = (x[1],x[2])

equal1d =  ArrowType{1,1}([ArrayType(:N)],
                          [ArrayType(:N)],
                          [])

cos1dfunc = PrimFunc(equal1d, :cos)
sin1dfunc = PrimFunc(equal1d, :sin)
tan1dfunc = PrimFunc(equal1d, :tan)

equal2d =  ArrowType{1,1}([ArrayType(:N, :M)],
                          [ArrayType(:N, :M)],
                          [])

cos2dfunc = PrimFunc(equal2d, :cos)
sin2dfunc = PrimFunc(equal2d, :sin)
tan2dfunc = PrimFunc(equal2d, :tan)

# Binary Functions
binequal1d =  ArrowType{2,1}([ArrayType(:N), ArrayType(:N)],
                             [ArrayType(:N)],
                             [])
addfunc = PrimFunc(binequal1d, :+)
minusfunc = PrimFunc(binequal1d, :-)

# # Concat
binconcat = ArrowType{2,1}([ArrayType(:N), ArrayType(:N)],
                           [ArrayType(:(N+M))],
                           [])

concatfunc = PrimFunc(binconcat, :concat)

clone1d  = ArrowType{1,2}([ArrayType(:N)],
                          [ArrayType(:N), ArrayType(:N)],
                          [])

clone1dfunc = PrimFunc(clone1d, :clone)
