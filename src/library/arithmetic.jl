## Primitive Tensor Functions
## ==========================

const arith_typ = ArrowType{2,1}([ArrayType(:N), ArrayType(:N)],
                                 [ArrayType(:N)],
                                 [])

"Class of arrows for primitive unary arithmetic operations"
immutable ArithArrow <: PrimArrow{2, 1}
  name::Symbol
end

typ(x::ArithArrow) = arith_typ
name(a::ArithArrow) = a.name

## Primitive Arithmetic Arrows
## ===========================

const addarr = ArithArrow(:+)
const minusarr = ArithArrow(:-)
const divsarr = ArithArrow(:/)
const mularr = ArithArrow(:*)
const powarr = ArithArrow(:^)

export addarr, minusarr, divsarr, mularr, powarr
