## Primitive Convolutional Arrows
## ==============================

x1typ = @shape x1 [batch, stakc, row, col]
x2typ = @shape x2 [filter, stack, row, col]
x3typ = @shape x1 [batch, stakc, row, col]

const conv_typ = @arrtype [x1typ, x2typ] [x3typ]

"Class of arrows for primitive binary arithmetic operations, + / + ^"
immutable ConvArrow <: PrimArrow{2, 1} end

name(::ConvArrow) = :conv2d
typ(x::ConvArrow) = conv_typ

const conv2darr = ConvArrow()
export conv2darr

## Max Pooling
## ===========

# "Max Pooling"
# immutable MaxPool2DArrow <: PrimArrow{1, 1}
#   typ::Arrows.ArrowType{1, 1}
#   maxpool_shape::Tuple{Integer, Integer}
#   function MaxPool2DArrow(maxpool_shape::Tuple{Integer, Integer})
#     warn("hack, fixme for type length")
#     typ = ArrowType{1, 1}([ArrayType(:M, :N)], [ArrayType(:BATCHSIZE, :STACK)], [])
#     # typ = dummyarrtype(1, 1)
#     # Generate the type of the arrow based on the pattern,
#     new(typ, maxpool_shape)
#   end
# end
#
# name(::MaxPool2DArrow) = :maxpool2d
# typ(m::MaxPool2DArrow) = m.typ
#
# maxpool2d(maxpool_shape::Tuple{Integer, Integer}) = MaxPool2DArrow(maxpool_shape)
#
# export maxpool2d
