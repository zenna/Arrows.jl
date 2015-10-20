## Primitive Arrow
## ===============

abstract PrimArrow{I, O} <: Arrow{I, O}

"Parameters of a primitive arrow"
parameters(x::PrimArrow) = Dict{Symbol, Any}()

"number of arrows"
nnodes(a::PrimArrow) = 1
nodes(a::PrimArrow) = Arrow[a]

inppintype(x::PrimArrow, pinid::PinId) = typ(x).inptypes[pinid]
outpintype(x::PrimArrow, pinid::PinId) = typ(x).outtypes[pinid]

# Intercace methods
name(x::PrimArrow) = error("interface: children should implement this")
typ(x::PrimArrow) = error("interface: children should implement this")

# Printing
string{I,O}(x::PrimArrow{I,O}) =
  "$(name(x)) :: PrimArrow{$I,$O}\n$(name(x)) :: $(string(typ(x)))"
print(io::IO, x::PrimArrow) = print(io, string(x))
println(io::IO, x::PrimArrow) = println(io, string(x))
show(io::IO, x::PrimArrow) = print(io, string(x))
showcompact(io::IO, x::PrimArrow) = print(io, string(x))
