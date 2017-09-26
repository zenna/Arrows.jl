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
