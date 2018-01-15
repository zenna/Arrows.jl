"Inverse Xor"
function inv_xor()
  c = CompArrow(:inv_xor, [:z, :θxor], [:x, :y])
  z, θ = ▹(c)
  x, y = ◃(c)
  addprop!(θp, θ)
  z ⊻ θ ⥅ x
  θ ⥅ y
  c
end
