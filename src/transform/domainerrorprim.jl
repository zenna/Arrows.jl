# Domain Errors #
function sub_domain_error(carr::PartialArrow, sarr::SubArrow)
  ϵcarr = wrap(carr, Symbol(:ϵcarr_, name(carr)))
  outsprts = tuple_untupled(δdomain(carr, ▹s(ϵcarr)...))
  # outsprts = map(smootherstep, outsprts)
  foreach(link_to_parent!, outsprts)
  foreach(sprt -> addprop!(domϵ, deref(sprt)), dst.(outsprts))
  @assert is_wired_ok(ϵcarr)
  (ϵcarr, id_portid_map(carr))
end

δdomain(arr::SqrtArrow, x) = ifelse(x < 0, abs(x), 0)
δdomain(arr::ACosArrow, x) = δinterval(x, -1, 1)
δdomain(arr::ASinArrow, x) = δinterval(x, -1, 1)
function δdomain{I}(arr::InvDuplArrow{I}, args...)
  compose!([args...], VarArrow(I))
end
