## Primitive Arrow
## ===============

abstract PrimArrow{I, O} <: Arrow{I, O}

ports{I, O}(arr::PrimArrow{I, O}) = [Port(arr, i) for i = 1:I+O]

# Intercace methods
name(x::PrimArrow) = error("interface: children should implement name")
typ(x::PrimArrow) = error("interface: children should implement typ")
dimtyp(x::PrimArrow) = error("interface: children should implement dimtyp")
