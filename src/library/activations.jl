## activation functions
## ====================

const sigmoid_typ = ArrowType{1,1}([ArrayType(:N)], [ArrayType(:N)],[])

"Class of arrows for sigmoids"
immutable SigmoidArrow <: PrimArrow{1, 1}
  name::Symbol
end

typ(x::ActivationArrow) = arith_typ

## Primitive Arithmetic Arrows
## ===========================

const sigmoidarr = SigmoidArrow(:sigmoidarr)
const hard_sigmoidarr = SigmoidArrow(:hard_sigmoidarr)
const ultra_fast_sigmoidarr = SigmoidArrow(:ultra_fast_sigmoidarr)
