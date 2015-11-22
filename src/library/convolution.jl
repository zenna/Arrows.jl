## Primitive Convolutional Arrows
## ==============================
import SMTBase
begin
  # Let's generate the type
  local etyp = arrowelem((Real, Integer, Real), (Real,))
  local dtyp = arrowdim((3, 0, 4), (3,))
  wout, w, fw, hout, h, fh = nonnegparam(Integer, :wout), nonnegparam(Integer, :w),
          nonnegparam(Integer, :fw), nonnegparam(Integer, :hout), nonnegparam(Integer, :h),
          nonnegparam(Integer, :fh)
  local border = Parameter{Bool}(:border)
  local c = ifelse(borderparam, (wout == w - fw + 1) & (hout == h - fh + 1),
                          (wout == w + fw - 1) & (hout == h + fh - 1))

  local valshptyp = arrowshp(( (:fw, :wh), (0,), (:w, :h, :c) ), ( (:wout, :hout), ), c)
  arith_typ = ExplicitArrowType(etyp, dtyp, shptyp, ConstraintSet())

  conv_typ = Arrows.ArrowType{3,1}(dtype, tuple(fil,border,img), tuple(convimg), cset)
end

begin
  x =  Arrows.shpparams((:x,:y,:z))
  t = Arrows.vlparams((1,:s, :t))
  Arrows.ArrowParam2{1,1}((x,),(x,),SMTBase.ConstraintSet())
#
# local x1typ = @shape x1 [batch, stakc, row, col]
# x2typ = @shape x2 [filter, stack, row, col]
# x3typ = @shape x1 [batch, stakc, row, col]
#
# const conv_typ = @arrtype [x1typ, x2typ] [x3typ]
#
"""conv2d :: filter:{fw, fh}, border::Bool, img:{w, h, c} >> convimg:{wout, hout} |
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
