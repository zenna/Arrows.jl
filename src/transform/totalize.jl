# Approximate Totalization #

sub_aprx_totalize(sarr::SubArrow) = sub_aprx_totalize(deref(sarr), sarr)
sub_aprx_totalize(carr::CompArrow, sarr::SubArrow) = aprx_totalize!(carr)

"Fallback to do nothing if `parr` is total"
sub_aprx_totalize(parr::PrimArrow, sarr::SubArrow) = nothing

"""
Convert `arr` into `Arrow` which is a total function of inputs.

# Arguments:
- `arr` an `Arrow` that is partial with respect  to its domaina
# Returns:
- `total_arr`: an apprximate totalization of arr, i.e.
               arr(x) = f(x) = ⊥ ? any y ∈ Y : arr(x)
"""
aprx_totalize!(carr::CompArrow) = lightwalk(sub_aprx_totalize, identity, carr)
aprx_totalize(arr::CompArrow)::CompArrow = aprx_totalize!(deepcopy(arr))
aprx_totalize(parr::PrimArrow) = aprx_totalize!(wrap(parr))

# Errors of Approximate Totalization #
δdomain(arr::SqrtArrow, x) = δinterval(x, -1, 1)
δdomain(arr::ACosArrow, x) = δinterval(x, -1, 1)
δdomain(arr::ASinArrow, x) = δinterval(x, -1, 1)
δdomain(arr::DuplArrow, x) = VarArrow()

function siphon!(sarr::SubArrow)
  # Interface be either (1) a function that modifies the arrow or
  # get an arrow that I need to connect inputs to
  sprts = src.(in_sub_ports(sarr))
  f(sprts::SubPort...) = δdomain(deref(sarr), sprts...)
  res = compcall(f, :node_error, sprts...)
  foreach(ϵ!, res)
  # TODO: Replace aboe with:
  # ϵ!(@▸ δdomain(deref(sarr), src.(in_sub_ports(sarr))))
end

"""
Capture node_loss from every sub_arrow.

∀ sarr::SubArrow ∈ `arr`
if sarr is aprximate totalization of sarr_partial
  replace sarr with sarr

  arr = SqrtArrow() # arr(-1) = ⊥
  total_arr = Sqrt
"""
function aprx_errors!(arr::CompArrow)::CompArrow
  outer = carr -> link_to_parent!(carr, is_error_port ∧ loose)
  @show lightwalk(siphon!, outer, arr)
end

"Non mutating `aprx_errors`"
aprx_errors(arr::CompArrow)::CompArrow = aprx_errors!(deepcopy(arr))
aprx_errors(parr::PrimArrow) = aprx_errors!(wrap(parr))
