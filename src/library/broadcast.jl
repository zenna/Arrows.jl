"Broadcast Arrow"
struct BroadcastArrow <: PrimArrow
end
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
"Broadcast Arrow"
struct ExplicitBroadcastArrow <: PrimArrow
end
name(::ExplicitBroadcastArrow) = :bcast
props(::ExplicitBroadcastArrow) = [Props(true, :x, Any),
                                   Props(true, :size, Tuple),
                                   Props(false, :y, Array)]
abinterprets(::ExplicitBroadcastArrow) = [sizeprop]
function sizeprop(arr::ExplicitBroadcastArrow, props::IdAbValues)::IdAbValues
  if 1 ∈ keys(props) && :value ∈ props[1]
     bcastsize = props[1][:value]
     IdAbValues(2 => AbValues(:size => Size([bcastsize...])))
   else
     IdAbValues()
   end
end

function bcastarray(a::Array, size::Tuple)
end

function valueprop(arr::ExplicitBroadcastArrow, abvals::IdAbValues)::IdAbValues
  if in(idabv, 1, :value) && ub
    val = idabv[1][:value]
    sz = idabv[1][:size]
    inner = map()
    repeat(val, inner)
    # @show abvals[1]
    # @show abvals[2]
    # Do constant propagation
    # if :value ∈ abvals[1] ⊻ :value ∈ abvals[2]
    # @assert false
  end
  IdAbValues()
end

function constprop(arr::ExplicitBroadcastArrow, idabv::IdAbValues)::IdAbValues
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
