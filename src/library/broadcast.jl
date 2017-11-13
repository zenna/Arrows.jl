"Broadcast Arrow"
struct BroadcastArrow <: PrimArrow
end
name(::BroadcastArrow) = :bcast
props(::BroadcastArrow) = [Props(true, :x, Any), Props(false, :y, Any)]

struct InvBroadcastArrow <: PrimArrow
end

name(::InvBroadcastArrow) = :inv_bcast
props(::InvBroadcastArrow) = [Props(true, :y, Any), Props(false, :x, Any)]
abinterprets(::BroadcastArrow) = [sizeprop]
function sizeprop(arr::BroadcastArrow, props::IdAbValues)::IdAbValues
  # @show props
  # TODO: check constraints are ok
  # @assert false
  IdAbValues()
end

function valueprop(arr::BroadcastArrow, abvals::IdAbValues)::IdAbValues
  # @show abvals
  if 1 ∈ keys(abvals) && 2 ∈ keys(abvals)
    @show abvals[1]
    @show abvals[2]
    # @assert false
  end
  IdAbValues()
end
