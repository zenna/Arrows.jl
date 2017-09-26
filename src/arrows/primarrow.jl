## Primitive Arrow
## ===============

abstract type PrimArrow <: Arrow end
props(arr::PrimArrow, port::Port) = props(arr)[port.port_id]

name(x::PrimArrow) = error("interface: children should implement name")
typ(x::PrimArrow) = error("interface: children should implement typ")
dimtyp(x::PrimArrow) = error("interface: children should implement dimtyp")
