# Primitives for approximate totalization #
sub_aprx_totalize{I}(arr::InvDuplArrow{I}) = (aprx_inv_dupl(I), identity_portid_map(arr))
aprx_inv_dupl(n::Integer) = MeanArrow(n)

# sub_aprx_totalize(carr::ASinArrow) =
#     (ClipArrow{-1.0, 1.0}() >> carr, identity_portid_map(carr))
# sub_aprx_totalize(carr::ACosArrow) =
#     (ClipArrow{-1.0, 1.0}() >> carr, identity_portid_map(carr))
# sub_aprx_totalize(carr::SqrtArrow) =
#     @show (ClipArrow{0.0, 1e6}() >> carr, identity_portid_map(carr))
