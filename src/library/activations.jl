## activation functions
## ====================
arb_array = @shape s [x_i for i = 1:n]
const sigmoid_typ = @arrtype [arb_array] [arb_array]

"Class of arrows for sigmoids"
immutable SigmoidArrow <: PrimArrow{1, 1}
  name::Symbol
end

name(x::SigmoidArrow) = x.name
typ(x::SigmoidArrow) = sigmoid_typ

## Primitive Arithmetic Arrows
## ===========================

const sigmoidarr = SigmoidArrow(:sigmoid)
const hard_sigmoidarr = SigmoidArrow(:hard_sigmoid)
const ultra_fast_sigmoidarr = SigmoidArrow(:ultra_fast_sigmoid)

export sigmoidarr, hard_sigmoidarr, ultra_fast_sigmoidarr
