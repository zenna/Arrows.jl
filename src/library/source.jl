"Takes no input simple emits a `value::T`"
struct SourceArrow{T} <: PrimArrow
  value::T
end

name(::SourceArrow) = :source
props{T}(::SourceArrow{T}) =  [Props(false, :x, T)]

# FIXME, Specialize this for different types
zero(::Type{SubPort}) = SourceArrow(0)
one(::Type{SubPort}) = SourceArrow(1)
