# Errors of Approximate Totalization #
sub_domain_error(sarr::SubArrow) = sub_domain_error(deref(sarr), sarr)
sub_domain_error(carr::CompArrow, sarr::SubArrow) =
  (domain_error(carr), id_portid_map(carr))
sub_domain_error(parr::PrimArrow, sarr::SubArrow) = (parr, id_portid_map(parr))

"""
Quantitative measure of domain Error.
Distance from input to subset of domain that is well defined.

From `f:X -> Y`, derive `f:X -> Y × Ε`, where e ∈ E = δ(x, {x | f(x) != ⊥}`
"""
function domain_error!(carr::CompArrow)::CompArrow
  link_loose_srcs(carr) = link_to_parent!(carr, loose ∧ should_src)
  outer = inv_rename! ∘ link_loose_srcs
  walk!(sub_domain_error, outer, carr)
end

"Non mutating `domain_error`"
domain_error(carr::CompArrow)::CompArrow = domain_error!(deepcopy(carr))
domain_error(parr::PrimArrow) = domain_error!(wrap(parr))
