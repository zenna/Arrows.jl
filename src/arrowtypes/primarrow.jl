## Primitive Arrow
## ===============
"A primitived arrow is a lifted primitive function"
immutable PrimArrow{I, O} <: Arrow{I, O}
  typ::ArrowType
  func::PrimFunc
end

name(a::PrimArrow) = a.func.name

"number of arrows"
nnodes(a::PrimArrow) = 1
nodes(a::PrimArrow) = Arrow[a]

inppintype(x::PrimArrow, pinid::PinId) = x.typ.inptypes[pinid]
outpintype(x::PrimArrow, pinid::PinId) = x.typ.outtypes[pinid]

# Printing
string{I,O}(x::PrimArrow{I,O}) =
  "$(x.func.name) :: PrimArrow{$I,$O}\n$(x.func.name) :: $(string(x.typ))"
print(io::IO, x::PrimArrow) = print(io, string(x))
println(io::IO, x::PrimArrow) = println(io, string(x))
show(io::IO, x::PrimArrow) = print(io, string(x))
showcompact(io::IO, x::PrimArrow) = print(io, string(x))
