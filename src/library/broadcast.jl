"Broadcast Arrow"
struct BroadcastArrow <: PrimArrow
end
#TODO: think on how to implement this
"default implementation, do nothing"
bcast(x) = x
name(::BroadcastArrow) = :bcast
props(::BroadcastArrow) = [Props(true, :x, Any), Props(false, :y, Any)]
abinterprets(::BroadcastArrow) = [sizeprop]
function sizeprop(arr::BroadcastArrow, props::IdAbValues)::IdAbValues
  # TODO: check constraints are ok
  IdAbValues()
end

function valueprop(arr::BroadcastArrow, idabv::IdAbValues)::IdAbValues
  # @show idabv
  if 1 ∈ keys(idabv) && 2 ∈ keys(idabv)
    # @show idabv[1]
    # @show idabv[2]
    # Do constant propagation
    # if :value ∈ idabv[1] ⊻ :value ∈ idabv[2]
    # @assert false
  end
  IdAbValues()
end

function constprop(arr::BroadcastArrow, idabv::IdAbValues)::IdAbValues
  # If any re constant all are constant!
  if any([isconst(pid, idabv) for pid in port_id.(⬧(arr))])
    # @assert false
    IdAbValues(pid => AbValues(:isconst => true) for pid in port_id.(◂(arr)))
  else
    IdAbValues()
  end
end

struct InvBroadcastArrow <: PrimArrow
end
#TODO: think on how to implement this
"default implementation, do nothing"
inv_bcast(x) = x
name(::InvBroadcastArrow) = :inv_bcast
props(::InvBroadcastArrow) = [Props(true, :y, Any), Props(false, :x, Any)]

function sizeprop(arr::InvBroadcastArrow, idabv::IdAbValues)::IdAbValues
  return IdAbValues()
  # @assert false
  # If any re constant all are constant!
  if any([isconst(pid, idabv) for pid in port_id.(⬧(arr))])
    # @assert false
    IdAbValues(pid => AbValues(:isconst => true) for pid in port_id.(◂(arr)))
  else
    IdAbValues()
  end
end
abinterprets(::InvBroadcastArrow) = [sizeprop]

function inv(arr::BroadcastArrow, sarr::SubArrow, idabv::IdAbValues)
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
function sizeprop(arr::ExplicitBroadcastArrow, props::IdAbValues)::IdAbValues
  if 2 ∈ keys(props) && :value ∈ keys(props[2])
     bcastsize = props[2][:value]
     IdAbValues(3 => AbValues(:size => Size([bcastsize.value...])))
   else
     IdAbValues()
   end
end

"Explicitly broadcast `x` into size `sz`"
explicitbroadcast(x::Number, sz::Tuple{Vararg{Int}}) = fill(x, sz)

function valueprop(arr::ExplicitBroadcastArrow, idabv::IdAbValues)::IdAbValues
  if in(idabv, 1, :value) && in(idabv, 2, :value)
    val = idabv[1][:value]
    sz = idabv[2][:value]
    bcasted = explicitbroadcast(val.value, sz.value)
    return IdAbValues(3 => AbValues(:value => Singleton(bcasted)))
  end
  IdAbValues()
end

struct ExplicitInvBroadcastArrow <: PrimArrow
end
name(::ExplicitInvBroadcastArrow) = :inv_exbcast
props(::ExplicitInvBroadcastArrow) = [Props(true, :y, Any),
                                      Props(true, :size, Tuple),
                                      Props(false, :x, Any)]

# function sizeprop(arr::ExplicitInvBroadcastArrow, idabv::IdAbValues)::IdAbValues
#   return IdAbValues()
#   # @assert false
#   # If any re constant all are constant!
#   if any([isconst(pid, idabv) for pid in port_id.(⬧(arr))])
#     # @assert false
#     IdAbValues(pid => AbValues(:isconst => true) for pid in port_id.(◂(arr)))
#   else
#     IdAbValues()
#   end
# end
# abinterprets(::ExplicitInvBroadcastArrow) = [sizeprop]

function inv(arr::ExplicitBroadcastArrow, sarr::SubArrow, idabv::IdAbValues)
  if all([isconst(pid, idabv) for pid in port_id.(▸(arr))])
    ExplicitBroadcastArrow(), Dict(:x => :x, :size => :size, :y => :y)
    # Need to know size of x
  elseif 1 ∈ keys(idabv) && :size in keys(idabv[1])
    sz = idabv[1][:size]
    @show sz
    # FIXME: Decide between tuple{Int...} and Size
    tpl_sz = tuple(get(sz)...)
    carr = CompArrow(:inv_bcast, [:y], [:x])
    szsarr = add_sub_arr!(carr, source(tpl_sz))
    invbcast = ExplicitInvBroadcastArrow()(▹(carr, 1), ◃(szsarr, 1))
    invbcast ⥅ ◃(carr, 1)
    @assert is_wired_ok(carr)
    carr, Dict(:x => :x, :y => :y)
  end
end
