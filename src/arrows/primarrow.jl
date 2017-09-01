## Primitive Arrow
## ===============

abstract type PrimArrow{I, O} <: Arrow{I, O} end
port_props(arr::PrimArrow, port::Port) = port_props(arr)[port.index]

name(x::PrimArrow) = error("interface: children should implement name")
typ(x::PrimArrow) = error("interface: children should implement typ")
dimtyp(x::PrimArrow) = error("interface: children should implement dimtyp")
