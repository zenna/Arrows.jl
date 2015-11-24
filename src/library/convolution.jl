## Primitive Convolutional Arrows
## ==============================
import SMTBase
begin
  filter = ShapeArray((:nf, :nc, :fw, :fh))
  borderparam = Parameter{Bool}(:border)
  border = ValueArray(borderparam)
  imgin = ShapeArray((:nimg, :w, :h, :c))
  imgout = ShapeArray((:nf, :nimg, :wout, :hout))
  wout, w, fw, hout, h, fh = map(sym->nonnegparam(Integer, sym),
                                (:wout, :w, :fw, :hout, :h, :fh))
  c = ifelse(borderparam, (wout == w - fw + 1) & (hout == h - fh + 1),
                     (wout == w + fw - 1) & (hout == h + fh - 1))

  conv_typ = ExplicitArrowType{3, 1}((filter, border, imgin), (imgout,), ConstraintSet([c]))
end

"""conv2d :: filter:{nf, fw, fh}, border::Bool, img:{ni, w, h, c} >> convimg:{ni, wout, hout} |
           if border then wout == w - fw + 1 & hout == h - fh + 1
              else wout == w + fw - 1 & hout == h + fh - 1"""
immutable ConvArrow <: PrimArrow{3, 1}
  typ::ArrowType
end

ConvArrow() = ConvArrow(conv_typ)
name(::ConvArrow) = :conv2d
typ(x::ConvArrow) = x.typ

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
