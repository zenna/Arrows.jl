"Find any `x` such that `f(x...) == y`"
function invpoint(f::Arrow, y...; loss = idloss)
  ftabv = PrtAbValues(zip(▸f, [AbValues(:value => x) for x in xs]))
  f⁻¹ = aprx_invert(f, ftabv)
  f⁻¹tabv = traceprop!(f⁻¹, ftabv)
  loss = idloss()
  optimize().argmin
end
