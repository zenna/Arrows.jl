## Primitive Arrow
## ===============

abstract PrimArrow{I, O} <: Arrow{I, O}
port_attrs(arr::PrimArrow, port::Port) = port_attrs(arr)[port.index]

name(x::PrimArrow) = error("interface: children should implement name")
typ(x::PrimArrow) = error("interface: children should implement typ")
dimtyp(x::PrimArrow) = error("interface: children should implement dimtyp")
