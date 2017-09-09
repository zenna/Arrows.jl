"Replace an inverse dupl with one that takes the mean"

identity_portid_map(arr) = PortIdMap(i => i for i = 1:num_ports(arr))
aprx(arr::Arrow) = (arr, identity_portid_map(arr))
aprx{I}(arr::InvDuplArrow{I}) = (approx_inv_dupl(I), identity_portid_map(arr))
aprx(carr::CompArrow) = (approx_totalize!(carr), identity_portid_map(carr))
aprx(sarr::SubArrow) = aprx(deref(sarr))
approx_inv_dupl(n::Integer) = MeanArrow(n)

"Convert `arr` into one which is a total function"
function approx_totalize!(arr::CompArrow)
  walk!(aprx, identity, arr)
end
