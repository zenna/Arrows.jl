## Primitive Convolutional Arrows
## ==============================

const conv_typ = ArrowType{2, 1}([ArrayType(:BATCHSIZE, :STACK, :ROW, :COW),
                                 ArrayType(:FILTERS, :STACK, :ROW, :COW)],
                                 [ArrayType(:BATCHSIZE, :STACK, :ROW, :COW)],
                                [])

"Class of arrows for primitive binary arithmetic operations, + / + ^"
immutable ConvArrow <: PrimArrow{2, 1} end

name(::ConvArrow) = :conv2d
typ(x::ConvArrow) = conv_typ

const conv2darr = ConvArrow()
export conv2darr
