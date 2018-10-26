using Memoize
# Approximate Totalization #

sub_aprx_totalize(sarr::SubArrow) = sub_aprx_totalize(deref(sarr), sarr)
sub_aprx_totalize(carr::CompArrow, sarr::SubArrow) = aprx_totalize!(carr)

"Fallback to do nothing if `parr` is total"
sub_aprx_totalize(parr::PrimArrow, sarr::SubArrow) = nothing

@memoize function __non_zero_clip_ε()
  clip_ε = CompArrow(:clip_ε_non_zero,
                      [:den, :num],
                      [:denout, :numout])
  den, num, denout, numout = ⬨(clip_ε)
  add = (x)-> add_sub_arr!(clip_ε, x)
  to_bcast = (x) -> ◃(x |> SourceArrow |> add,1) |> bcast
  zero = 0 |> to_bcast
  ε_val = 0.001 |> to_bcast
  comparison = EqualArrow()(num, zero)
  ε = ifthenelse(comparison, ε_val, zero)
  num + ε ⥅ numout
  den  ⥅ denout
  clip_ε
end

function non_zero!(sarr::SubArrow)
  inner_compose!(sarr, __non_zero_clip_ε())
end

sub_aprx_totalize(carr::DivArrow, sarr::SubArrow) = non_zero!(sarr)

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


sub_aprx_totalize2(sarr::SubArrow) = sub_aprx_totalize2(deref(sarr), sarr)
sub_aprx_totalize2(carr::CompArrow, sarr::SubArrow) = aprx_totalize2!(carr)
sub_aprx_totalize2(arr, sarr::SubArrow) = sub_aprx_totalize(arr, sarr)
aprx_totalize2!(carr::CompArrow) = lightwalk(sub_aprx_totalize2, identity, carr)
aprx_totalize2(arr::CompArrow)::CompArrow = aprx_totalize2!(deepcopy(arr))
aprx_totalize2(parr::PrimArrow) = aprx_totalize2!(wrap(parr))
