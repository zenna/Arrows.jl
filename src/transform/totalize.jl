# Approximate Totalization #

sub_aprx_totalize(sarr::SubArrow) = sub_aprx_totalize(deref(sarr), sarr)
sub_aprx_totalize(carr::CompArrow, sarr::SubArrow) = aprx_totalize!(carr)

"Fallback to do nothing if `parr` is total"
sub_aprx_totalize(parr::PrimArrow, sarr::SubArrow) = nothing

function non_zero!(sarr::SubArrow)
  clip_ε = CompArrow(:clip_ε |> gensym,
                      [:den, :num],
                      [:denout, :numout])
  den, num, denout, numout = ⬨(clip_ε)
  add = (x)-> add_sub_arr!(clip_ε, x)
  to_bcast = (x) -> ◃(x |> SourceArrow |> add,1) |> bcast
  zero = 0 |> to_bcast
  ε_val = 0.001 |> to_bcast
  comparison = EqualArrow()(num, zero)
  ε = ifelse(comparison, ε_val, zero)
  num + ε ⥅ numout
  den  ⥅ denout
  @assert is_wired_ok(clip_ε)
  inner_compose!(sarr, clip_ε)
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
