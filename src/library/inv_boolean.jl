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
