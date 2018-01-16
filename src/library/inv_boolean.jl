"Inverse Xor"
function inv_xor()
  c = CompArrow(:inv_xor, [:z, :θxor], [:x, :y])
  z, θ = ▸(c)
  x, y = ◂(c)
  addprop!(θp, θ)
  xor = add_sub_arr!(c, XorArrow())
  z ⥅ (xor, 1)
  θ ⥅ (xor, 2)
  (xor, 1) ⥅ x
  θ ⥅ y
  c
end

"Inverse or"
function inv_or()
  c = CompArrow(:inv_or, [:z, :θor1, :θor2], [:x, :y])
  z, θor1, θor2, x, y = ⬨(c)
  ifelse(z,
         θor1 & !θor2,
         θor1 ⊻ θor2) ⥅ x
  z ⥅ y
  @assert is_wired_ok(c)
  c
end
