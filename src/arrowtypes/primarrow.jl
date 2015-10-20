## Primitive Arrow
## ===============

abstract PrimArrow{I, O} <: Arrow{I, O}

"Parameters of a primitive arrow"
parameters(x::PrimArrow) = Dict{Symbol, Any}()

"number of arrows"
nnodes(a::PrimArrow) = 1
nodes(a::PrimArrow) = Arrow[a]

inppintype(x::PrimArrow, pinid::PinId) = x.typ.inptypes[pinid]
outpintype(x::PrimArrow, pinid::PinId) = x.typ.outtypes[pinid]

# Printing
string{I,O}(x::PrimArrow{I,O}) =
  "$(name(x)) :: PrimArrow{$I,$O}\n$(name(x)) :: $(string(x.typ))"
print(io::IO, x::PrimArrow) = print(io, string(x))
println(io::IO, x::PrimArrow) = println(io, string(x))
show(io::IO, x::PrimArrow) = print(io, string(x))
showcompact(io::IO, x::PrimArrow) = print(io, string(x))
