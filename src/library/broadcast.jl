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

struct InvBroadcastArrow <: PrimArrow
end
name(::InvBroadcastArrow) = :inv_bcast
props(::InvBroadcastArrow) = [Props(true, :y, Any), Props(false, :x, Any)]


function valueprop(arr::BroadcastArrow, abvals::IdAbValues)::IdAbValues
  # @show abvals
  if 1 ∈ keys(abvals) && 2 ∈ keys(abvals)
    # @show abvals[1]
    # @show abvals[2]
    # @assert false
  end
  IdAbValues()
end

function inv(::BroadcastArrow, sarr::SubArrow, abvals::IdAbValues)
  InvBroadcastArrow(), Dict(:x => :x, :y => :y)
end
