## Primitive Tensor Functions
## ==========================

# Issues
# - Don't have a way to support arbitrary number of dimensions yet.
# - Type signatures are clunky
# -

clone(x::Vector) = (x[1],x[2])

function build(funcs)
  for f in funcs
    for i = 1:1
      op = symbol(f, i)
      genfuncexpr = Expr(:(=), op, Expr(:call, :PrimFunc, :equal1d, QuoteNode(f)))
      eval(genfuncexpr)
      eval( Expr(:export, op))
    end
  end
end

## Unary Functions
## ==============
equal1d = ArrowType{1,1}([ArrayType(:N)], [ArrayType(:N)],[])

const trig_funcs = [:exp, :log, :sin, :cos, :tan, :asin, :acos, :atan, :sinh,
  :cosh, :tanh, :atan2, :sqrt, :sigmoid]
const activation_funcs = [:sigmoid, :ultra_fast_sigmoid, :hard_sigmoid,
  :softplus, :softmax, :relu]

unary_funcs = vcat(trig_funcs, activation_funcs)
for f in unary_funcs
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

conv2dfunctype = ArrowType{2, 1}([ArrayType(:BATCHSIZE, :STACK, :ROW, :COW),
                            ArrayType(:FILTERS, :STACK, :ROW, :COW)],
                           [ArrayType(:BATCHSIZE, :STACK, :ROW, :COW)],
                           [])
conv2dfunc = PrimFunc(conv2dfunctype, :conv2d)

# Relu

relufunctype = ArrowType{1, 1}([ArrayType(:A)], [ArrayType(:A)], [])
relu1dfunc = PrimFunc(relufunctype, :relu)
