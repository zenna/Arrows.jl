"Takes no input simple emits a `value::T`"
@auto_hash_equals struct SourceArrow{T} <: PrimArrow
  value::T
end

name(::SourceArrow) = :source
props(::SourceArrow{T}) where T =  [Props(false, :x, T)]
source(value) = SourceArrow(value)

"Broadcasted Source"
function bsource(x)
  c = CompArrow(:bsource)
  ssarr = add_sub_arr!(c, source(x))
  bsarr = add_sub_arr!(c, Arrows.BroadcastArrow())
  ◃(ssarr, 1) ⥅ ▹(bsarr, 1)
  link_to_parent!(◃(bsarr, 1))
  c
end

"Broadcasting source arrow, connect to arr, and return outport"
function bsource!(arr::Arrow, x)
  ssarr = add_sub_arr!(arr, source(x))
  bsarr = add_sub_arr!(arr, Arrows.BroadcastArrow())
  ◃(ssarr, 1) ⥅ ▹(bsarr, 1)
  ◃(bsarr, 1)
end

# FIXME: Specialize this to things which have sizes, maybe
function sizeprop(arr::SourceArrow{T}, props::IdAbVals) where T
  if T <: Union{Number, Array}
    IdAbVals(1 => AbVals(:size => Size([size(arr.value)...])))
  else
    IdAbVals()
  end
end

abinterprets(::SourceArrow{<:Union{Array, Number}}) = [sizeprop]
valueprop(arr::SourceArrow, props::IdAbVals) =
  IdAbVals(1 => AbVals(:value => Singleton(arr.value)))
constprop(arr::SourceArrow, props::IdAbVals)::IdAbVals =
  IdAbVals(1 => AbVals(:isconst => true))

# FIXME, Specialize this for different types
zero(::Type{SubPort}) = SourceArrow(0)
one(::Type{SubPort}) = SourceArrow(1)

string(arr::SourceArrow) = string(func_decl(arr), " := ", arr.value)
