"Takes no input simple emits a `value::T`"
@auto_hash_equals struct SourceArrow{T} <: PrimArrow
  value::T
end

name(::SourceArrow) = :source
props{T}(::SourceArrow{T}) =  [Props(false, :x, T)]
source(value) = SourceArrow(value)

# FIXME: Specialize this to things which have sizes, maybe
function sizeprop{T}(arr::SourceArrow{T}, props::IdAbValues)
  if T <: Union{Number, Array}
    IdAbValues(1 => AbValues(:size => Size([size(arr.value)...])))
  else
    IdAbValues()
  end
end

abinterprets(::SourceArrow{<:Union{Array, Number}}) = [sizeprop]
valueprop(arr::SourceArrow, props::IdAbValues) =
  IdAbValues(1 => AbValues(:value => Singleton(arr.value)))
constprop(arr::SourceArrow, props::IdAbValues)::IdAbValues =
  IdAbValues(1 => AbValues(:isconst => true))

# FIXME, Specialize this for different types
zero(::Type{SubPort}) = SourceArrow(0)
one(::Type{SubPort}) = SourceArrow(1)
