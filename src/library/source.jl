"Takes no input simple emits a `value::T`"
struct SourceArrow{T} <: PrimArrow{0, 1}
  value::T
end

name(::SourceArrow) = :source
port_attrs{T}(::SourceArrow{T}) =  [PortAttrs(false, :x, Array{T})]
