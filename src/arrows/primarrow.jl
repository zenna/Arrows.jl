## Primitive Arrow
## ===============

abstract PrimArrow{I, O} <: Arrow{I, O}

# eleminppintype(x::PrimArrow, pinid::PinId) = typ(x).elemtype.inptypes[pinid]
# elemoutpintype(x::PrimArrow, pinid::PinId) = typ(x).elemtype.outtypes[pinid]
# diminppintype(x::PrimArrow, pinid::PinId) = typ(x).dimtype.inptypes[pinid]
# dimoutpintype(x::PrimArrow, pinid::PinId) = typ(x).dimtype.outtypes[pinid]
# shapeinppintype(x::PrimArrow, pinid::PinId) = typ(x).shapetype.inptypes[pinid]
# shapeoutpintype(x::PrimArrow, pinid::PinId) = typ(x).shapetype.outtypes[pinid]
# valueinppintype(x::PrimArrow, pinid::PinId) = typ(x).valuetype.inptypes[pinid]
# valueoutpintype(x::PrimArrow, pinid::PinId) = typ(x).valuetype.outtypes[pinid]
#
# Intercace methods
name(x::PrimArrow) = error("interface: children should implement name")
typ(x::PrimArrow) = error("interface: children should implement typ")
dimtyp(x::PrimArrow) = error("interface: children should implement dimtyp")

# "Expression for dimensionality type at inport `p` of arrow `x`"
# dimexpr(x::PrimArrow, p::InPort) = ndims(typ(x).inptypes[p.pinid])
#
# "Expression for dimensionality type at outport `p` of arrow `x`"
# dimexpr(x::PrimArrow, p::OutPort) = ndims(typ(x).outtypes[p.pinid])
#
# "Number of dimensions of array at inport `p` of arrow `a`"
# function ndims{I, O}(a::PrimArrow{I, O}, p::InPort)
#   @assert p.pinid <= I
#   t::ArrowType = typ(a)
#   ndims(t.inptypes[p.pinid])
# end
#
# "Number of dimensions of array at inport `p` of arrow `a`"
# function ndims{I, O}(a::PrimArrow{I, O}, p::OutPort)
#   @assert p.pinid <= O
#   t::ArrowType = typ(a)
#   ndims(t.outtypes[p.pinid])
# end
#
# # Printing
# function string{I,O}(x::PrimArrow{I,O})
#   """$(name(x))\t:: PrimArrow{$I,$O}
#   eltyp\t:: $(arrtypf(typ(x), eltype))
#   ndims\t:: $(arrtypf(typ(x), ndims))
#   shape\t:: $(arrtypf(typ(x), shape; postprocess = parens))
#        \t | $(string(typ(x).constraints))"""
# end
