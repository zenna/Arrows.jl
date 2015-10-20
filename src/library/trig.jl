

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


# # Concat
binconcat = ArrowType{2,1}([ArrayType(:N), ArrayType(:N)],
                           [ArrayType(:(N+M))],
                           [])

concatfunc = PrimFunc(binconcat, :concat)

clone1d  = ArrowType{1,2}([ArrayType(:N)],
                          [ArrayType(:N), ArrayType(:N)],
                          [])
