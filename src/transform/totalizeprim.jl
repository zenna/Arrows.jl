# Primitives for approximate totalization #

PartialArrow = Union{SqrtArrow, ASinArrow, ACosArrow, InvDuplArrow}

function sub_aprx_totalize2(arr::InvDuplArrow{I}, sarr::SubArrow) where I
  meanarr = MeanArrow(I) >> DuplArrow(I)
  inner_compose!(sarr, meanarr)
end

function sub_aprx_totalize(arr::InvDuplArrow{I}, sarr::SubArrow) where I
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

@memoize function __ε_totalize_arr()
  clip_ε = CompArrow(:clip_ε_totalize, [:x], [:y])
  x, y = ⬨(clip_ε)
  add = (x)-> add_sub_arr!(clip_ε, x)
  to_bcast = (x) -> ◃(x |> SourceArrow |> add,1) |> bcast
  ε = exp(-10) |> to_bcast
  zero = 0 |> to_bcast
  ifelse(x > zero, x, ε) ⥅ y
  clip_ε
end

function ε_totalize!(sarr::SubArrow)
  inner_compose!(sarr, __ε_totalize_arr())
end

sub_aprx_totalize(carr::ASinArrow, sarr::SubArrow) = bounded_totalize!(sarr)
sub_aprx_totalize(carr::ACosArrow, sarr::SubArrow) = bounded_totalize!(sarr)
sub_aprx_totalize(carr::SqrtArrow, sarr::SubArrow) = nonneg_totalize!(sarr)
sub_aprx_totalize(carr::LogArrow, sarr::SubArrow) = ε_totalize!(sarr)
