"Attach the prefix pgf_ to the name of the arrow."
pgf_rename!(carr::CompArrow) = (rename!(carr, Symbol(:pgf_, carr.name)); carr)

"Inner method that will replace all the subarrows with their respective pgfs."
pgf_in(sarr::SubArrow, const_in) = pgf(deref(sarr), const_in)
"Outer method that connects the loose ports and renames the arrow."
pgf_out = pgf_rename! ∘ (carr -> link_to_parent!(carr, loose ∧ should_src))

"""Construct a parameter generating function (pgf) of carr
  Args:
    carr: the arrow to tranform
  Returns:
    A parameter generating function of carr that for a given input x outputs
    the corresponding value y as well as θ such that f^(-1)(y;θ) = x."""
function pgf_change!(carr::CompArrow, inner_pgf)
  for sarr in sub_arrows(carr)
    const_in = map(is_src_source, ▹(sarr))
    replarr, port_map = inner_pgf(sarr, const_in), id_portid_map(deref(sarr))
    replace_sub_arr!(sarr, replarr, port_map)
  end
  pgf_out(carr)
end

pgf(carr::CompArrow, inner_pgf=pgf_in) = pgf_change!(deepcopy(carr), inner_pgf)
