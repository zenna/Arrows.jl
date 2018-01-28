"Broadcast Arrow"
struct BroadcastArrow <: PrimArrow
end
#TODO: think on how to implement this
"default implementation, do nothing"
bcast(x) = x
name(::BroadcastArrow) = :bcast
props(::BroadcastArrow) = [Props(true, :x, Any), Props(false, :y, Any)]
abinterprets(::BroadcastArrow) = [sizeprop]
function sizeprop(arr::BroadcastArrow, props::IdAbVals)::IdAbVals
  # TODO: check constraints are ok
  IdAbVals()
end

function valueprop(arr::BroadcastArrow, idabv::IdAbVals)::IdAbVals
  # @show idabv
  if 1 ∈ keys(idabv) && 2 ∈ keys(idabv)
    # @show idabv[1]
    # @show idabv[2]
    # Do constant propagation
    # if :value ∈ idabv[1] ⊻ :value ∈ idabv[2]
    # @assert false
  end
  IdAbVals()
end

function constprop(arr::BroadcastArrow, idabv::IdAbVals)::IdAbVals
  # If any re constant all are constant!
  if any([isconst(pid, idabv) for pid in port_id.(⬧(arr))])
    # @assert false
    IdAbVals(pid => AbVals(:isconst => true) for pid in port_id.(◂(arr)))
  else
    IdAbVals()
  end
end

struct InvBroadcastArrow <: PrimArrow
end
#TODO: think on how to implement this
"default implementation, do nothing"
inv_bcast(x) = x
name(::InvBroadcastArrow) = :inv_bcast
props(::InvBroadcastArrow) = [Props(true, :y, Any), Props(false, :x, Any)]

function sizeprop(arr::InvBroadcastArrow, idabv::IdAbVals)::IdAbVals
  return IdAbVals()
  # @assert false
  # If any re constant all are constant!
  if any([isconst(pid, idabv) for pid in port_id.(⬧(arr))])
    # @assert false
    IdAbVals(pid => AbVals(:isconst => true) for pid in port_id.(◂(arr)))
  else
    IdAbVals()
  end
end
abinterprets(::InvBroadcastArrow) = [sizeprop]

function inv(arr::BroadcastArrow, sarr::SubArrow, idabv::IdAbVals)
  if any([isconst(pid, idabv) for pid in port_id.(⬧(arr))])
    BroadcastArrow(), Dict(:x => :x, :y => :y)
  else
    InvBroadcastArrow(), Dict(:x => :x, :y => :y)
  end
end

## Explicit Broadcast ##
"Explicit Broadcast Arrow"
struct ExplicitBroadcastArrow <: PrimArrow
end
name(::ExplicitBroadcastArrow) = :exbcast
props(::ExplicitBroadcastArrow) = [Props(true, :x, Any),
                                   Props(true, :size, Tuple),
                                   Props(false, :y, Array)]
abinterprets(::ExplicitBroadcastArrow) = [sizeprop]
function sizeprop(arr::ExplicitBroadcastArrow, props::IdAbVals)::IdAbVals
  if 2 ∈ keys(props) && :value ∈ keys(props[2])
     bcastsize = props[2][:value]
     IdAbVals(3 => AbVals(:size => Size([bcastsize.value...])))
   else
     IdAbVals()
   end
end

"Explicitly broadcast `x` into size `sz`"
explicitbroadcast(x::Number, sz::Tuple{Vararg{Int}}) = fill(x, sz)
explicitbroadcast(x::Number, sz::Array{Int}) = fill(x, Tuple(sz))
exbcast(x::Number, sz::Tuple{Vararg{Int}}) = fill(x, sz)

"Explicitly broadcast array `x` to array of dimensionality `sz`"
function exbcast(x::Array, sz::Tuple{Vararg{Int}})
  dim_multiples = map(size(x), sz) do a, b
    if b == 1
      a == 1 || throw(ArgumentError("Cannot broadcast dimensionality $a to $b"))
      1
    elseif a == 1 # e.g., b = 7, a = 1
      return b
    elseif a == b # e.g. b = 7, a = 7
      return 1
    else
      throw(ArgumentError("Cannot broadcast dimensionality $a to $b"))
    end
  end
  # TODO: is inner correct?
  repeat(x, inner=dim_multiples)
end

function exbcast(x::Array{T}, sz::Array) where T
  answer = Array{T}(sz...)
  broadcast!(identity, answer, x)
end

exbcast(x::Number, sz::Array) = explicitbroadcast(x, sz)


function valueprop(arr::ExplicitBroadcastArrow, idabv::IdAbVals)::IdAbVals
  if in(idabv, 1, :value) && in(idabv, 2, :value)
    val = idabv[1][:value]
    sz = idabv[2][:value]
    bcasted = explicitbroadcast(val.value, sz.value)
    return IdAbVals(3 => AbVals(:value => Singleton(bcasted)))
  end
  IdAbVals()
end

struct ExplicitInvBroadcastArrow <: PrimArrow
end
name(::ExplicitInvBroadcastArrow) = :inv_exbcast
props(::ExplicitInvBroadcastArrow) = [Props(true, :y, Any),
                                      Props(true, :size, Tuple),
                                      Props(false, :x, Any)]

# function sizeprop(arr::ExplicitInvBroadcastArrow, idabv::IdAbVals)::IdAbVals
#   return IdAbVals()
#   # @assert false
#   # If any re constant all are constant!
#   if any([isconst(pid, idabv) for pid in port_id.(⬧(arr))])
#     # @assert false
#     IdAbVals(pid => AbVals(:isconst => true) for pid in port_id.(◂(arr)))
#   else
#     IdAbVals()
#   end
# end
# abinterprets(::ExplicitInvBroadcastArrow) = [sizeprop]

function inv(arr::ExplicitBroadcastArrow, sarr::SubArrow, idabv::IdAbVals)
  if all([isconst(pid, idabv) for pid in port_id.(▸(arr))])
    ExplicitBroadcastArrow(), Dict(:x => :x, :size => :size, :y => :y)
    # Need to know size of x
  elseif 1 ∈ keys(idabv) && :size in keys(idabv[1])
    sz = idabv[1][:size]
    # FIXME: Decide between tuple{Int...} and Size
    tpl_sz = tuple(get(sz)...)
    carr = CompArrow(:inv_bcast, [:y], [:x])
    szsarr = add_sub_arr!(carr, source(tpl_sz))
    invbcast = ExplicitInvBroadcastArrow()(▹(carr, 1), ◃(szsarr, 1))
    invbcast ⥅ ◃(carr, 1)
    @assert is_valid(carr)
    carr, Dict(:x => :x, :y => :y)
  else
    throw(InvertError(arr, idabv))
  end
end
