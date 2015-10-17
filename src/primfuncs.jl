## Primitive Tensor Functions
## ==========================

clone(x::Vector) = (x[1],x[2])

# Id array type
equal1d = ArrowType{1,1}([ArrayType(:N)], [ArrayType(:N)],[])

for f in [:abs, :exp, :log, :sin, :cos, :tan, :asin, :acos, :atan, :sinh, :cosh,
          :tanh, :atan2, :sqrt]
  for i = 1:1
    op = symbol(f, i)
    genfuncexpr = Expr(:(=), op, Expr(:call, :PrimFunc, :equal1d, QuoteNode(f)))
    eval(genfuncexpr)
    eval( Expr(:export, op))
  end
end

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
