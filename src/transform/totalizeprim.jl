# Primitives for approximate totalization #

PartialArrow = Union{SqrtArrow, ASinArrow, ACosArrow, InvDuplArrow}

function sub_aprx_totalize{I}(arr::InvDuplArrow{I}, sarr::SubArrow)
  meanarr = MeanArrow(I) >> DuplArrow(I)
  inner_compose!(sarr, meanarr)
end

function bounded_totalize!(sarr::SubArrow)
  # TODO: Generalize this
  clipcarr = CompArrow(:clip, [:x], [:y])
  x, y = sub_ports(clipcarr)
  bounds = domain_bounds(deref(sarr))
  clip(x, bounds...) ⥅ y
  inner_compose!(sarr, clipcarr)
end

function nonneg_totalize!(sarr::SubArrow)
  clip_zero = CompArrow(:clip_zero, [:x], [:y])
  x, y = sub_ports(clip_zero)
  max(x, 0) ⥅ y
  inner_compose!(sarr, clip_zero)
end

sub_aprx_totalize(carr::ASinArrow, sarr::SubArrow) = bounded_totalize!(sarr)
sub_aprx_totalize(carr::ACosArrow, sarr::SubArrow) = bounded_totalize!(sarr)
sub_aprx_totalize(carr::SqrtArrow, sarr::SubArrow) = nonneg_totalize!(sarr)

# Aprx Errors #
function sub_aprx_error(carr::PartialArrow, sarr::SubArrow)
  ϵcarr = wrap(carr, Symbol(:ϵcarr_, name(carr)))
  outsprts = tuple_untupled(δdomain(carr, ▹s(ϵcarr)...))
  foreach(link_to_parent!, outsprts)
  foreach(ϵ!, dst.(outsprts))
  @assert is_wired_ok(ϵcarr)
  (ϵcarr, id_portid_map(carr))
end

δdomain(arr::SqrtArrow, x) = ifelse(x < 0, abs(x), 0)
δdomain(arr::ACosArrow, x) = δinterval(x, -1, 1)
δdomain(arr::ASinArrow, x) = δinterval(x, -1, 1)
function δdomain{I}(arr::InvDuplArrow{I}, args...)
  compose!([args...], VarArrow(I))
end
