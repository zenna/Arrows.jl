"Takes no input simple emits a `value::T`"
struct SourceArrow{T} <: PrimArrow{0, 1}
  value::T
end

name(::SourceArrow) = :source
port_props{T}(::SourceArrow{T}) =  [PortProps(false, :x, Array{T})]
