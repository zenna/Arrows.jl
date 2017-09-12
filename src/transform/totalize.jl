"Replace an inverse dupl with one that takes the mean"
identity_portid_map(arr) = PortIdMap(i => i for i = 1:num_ports(arr))

# Approximate Totalization #

## Arrow Types ##
sub_aprx_totalize(sarr::SubArrow) = sub_aprx_totalize(deref(sarr))
sub_aprx_totalize(carr::CompArrow) = (aprx_totalize(carr), identity_portid_map(carr))
sub_aprx_totalize(arr::PrimArrow) = (arr, identity_portid_map(arr))

## Primitives ##
sub_aprx_totalize{I}(arr::InvDuplArrow{I}) = (aprx_inv_dupl(I), identity_portid_map(arr))
aprx_inv_dupl(n::Integer) = MeanArrow(n)

sub_aprx_totalize(carr::ASinArrow) = (ClipArrow{-1.0, 1.0}() >> carr, identity_portid_map(carr))
sub_aprx_totalize(carr::ACosArrow) = (ClipArrow{-1.0, 1.0}() >> carr, identity_portid_map(carr))

"""Convert `arr` into `Arrow` which is a total function of inputs.

# Arguments:
- `arr` an `Arrow` that is partial with respect  to its domaina
# Returns:
- `total_arr`: an apprximate totalization of arr, i.e.
               arr(x) = f(x) = ⊥ ? any y ∈ Y : arr(x
"""
aprx_totalize!(arr::CompArrow) = walk!(sub_aprx_totalize, identity, arr)
aprx_totalize(arr::CompArrow)::CompArrow = aprx_totalize!(deepcopy(arr))
aprx_totalize(parr::PrimArrow) = aprx_totalize!(wrap(parr))

# Errors of Approximate Totalization #

# TODO
# 1. δinterval is wron
# 2. dont need walk because not replacing arrow, but maprecur doesnt have outer
#    - which we need to relink ports, so should change one of them
# 3. What's the right interface

"Construct an arrow which computes the distance to the interval [a, b]"
function δinterval(x, a, b)
  min(abs(x - a), abs(x - b))
end

δdomain(arr::SqrtArrow) = δinterval(x, -1, 1)
δdomain(arr::ACosArrow) = δinterval(x, -1, 1)
δdomain(arr::ASinArrow) = δinterval(x, -1, 1)
δdomain(arr::DuplArrow) = VarArrow()
# aprx_error(arr::ASinArrow) = distance to interval

function siphon(sarr::SubArrow)
  # Interface be either (1) a function that modifies the arrow or
  # get an arrow that I need to connect inputs to
  δdomain(deref(arr), in_sub_ports(sarr))
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
  walk!(siphon, (carr -> link_to_parent!(carr, is_error_port ∧ loose)), arr)
end

"Non mutating `aprx_errors`"
aprx_errors(arr::CompArrow)::CompArrow = aprx_errors(deepcopy(arr))
aprx_errors(parr::PrimArrow) = aprx_errors!(wrap(parr))
