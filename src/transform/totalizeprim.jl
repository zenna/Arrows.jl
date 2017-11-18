# Primitives for approximate totalization #

PartialArrow = Union{SqrtArrow, ASinArrow, ACosArrow, InvDuplArrow}

function sub_aprx_totalize{I}(arr::InvDuplArrow{I}, sarr::SubArrow)
  meanarr = MeanArrow(I) >> DuplArrow(I)
  inner_compose!(sarr, meanarr)
end

function sub_aprx_totalize2{I}(arr::InvDuplArrow{I}, sarr::SubArrow)
  meanarr = FirstArrow(I) >> DuplArrow(I)
  inner_compose!(sarr, meanarr)
end

function bounded_totalize!(sarr::SubArrow)
  # TODO: Generalize this
  clipcarr = CompArrow(:clip, [:x], [:y])
  x, y = ⬨(clipcarr)
  bounds = domain_bounds(deref(sarr))
  clip(x, bounds...) ⥅ y
  inner_compose!(sarr, clipcarr)
end

function nonneg_totalize!(sarr::SubArrow)
  clip_zero = CompArrow(:clip_zero, [:x], [:y])
  x, y = ⬨(clip_zero)
  max(x, 0) ⥅ y
  inner_compose!(sarr, clip_zero)
end

function ε_totalize!(sarr::SubArrow)
  clip_ε = CompArrow(:clip_ε, [:x], [:y])
  x, y = ⬨(clip_ε)
  ε = exp(-10)
  greater_than = (x > 0)
  (x * greater_than + ε * (1 - greater_than)) ⥅ y
  inner_compose!(sarr, clip_ε)
end

sub_aprx_totalize(carr::ASinArrow, sarr::SubArrow) = bounded_totalize!(sarr)
sub_aprx_totalize(carr::ACosArrow, sarr::SubArrow) = bounded_totalize!(sarr)
sub_aprx_totalize(carr::SqrtArrow, sarr::SubArrow) = nonneg_totalize!(sarr)
sub_aprx_totalize(carr::LogArrow, sarr::SubArrow) = ε_totalize!(sarr)
