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

function valueprop(arr::BroadcastArrow, abvals::IdAbValues)::IdAbValues
  # @show abvals
  if 1 ∈ keys(abvals) && 2 ∈ keys(abvals)
    # @show abvals[1]
    # @show abvals[2]
    # Do constant propagation
    # if :value ∈ abvals[1] ⊻ :value ∈ abvals[2]
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
