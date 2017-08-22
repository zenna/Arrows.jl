"Takes no input simple emits a `value::T`"
struct SourceArrow{T} <: PrimArrow{0, 1}
  id::Symbol
  value::T
end

name(::SourceArrow) = :source
SourceArrow{T}(value::T) = SourceArrow(gen_id(), value)
port_attrs{T}(::SourceArrow{T}) =  [PortAttrs(false, :x, Array{T})]
