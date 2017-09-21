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
sub_aprx_error(sarr::SubArrow) = sub_aprx_error(deref(sarr), sarr)
sub_aprx_error(carr::CompArrow, sarr::SubArrow) =
  (aprx_error(carr), id_portid_map(carr))
sub_aprx_error(parr::PrimArrow, sarr::SubArrow) = (parr, id_portid_map(parr))

"""
Quantitative measure of domain Error.
Distance from input to subset of domain that is well defined.

From `f:X -> Y`, derive `f:X -> Y × Ε`, where e ∈ E = δ(x, {x | f(x) != ⊥}`
"""
function aprx_error!(carr::CompArrow)::CompArrow
  link_loose_srcs(carr) = link_to_parent!(carr, loose ∧ should_src)
  outer = inv_rename! ∘ link_loose_srcs
  walk!(sub_aprx_error, outer, carr)
end

"Non mutating `aprx_error`"
aprx_error(carr::CompArrow)::CompArrow = aprx_error!(deepcopy(carr))
aprx_error(parr::PrimArrow) = aprx_error!(wrap(parr))
