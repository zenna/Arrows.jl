"Takes no input simple emits a `value::T`"
struct SourceArrow{T} <: PrimArrow
  value::T
end

name(::SourceArrow) = :source
port_props(::SourceArrow) =  [PortProps(false, :x, Array)]
