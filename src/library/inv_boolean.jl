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

"Inverse Or"
function inv_or()
  c = CompArrow(:inv_or, [:z, :θor1, :θor2], [:x, :y])
  z, θor1, θor2, x, y = ⬨(c)
  addprop!(θp, θor1)
  addprop!(θp, θor2)
  onetwo = !(θor1 & θor2)
  z & (θor1 ⊻ onetwo) ⥅ x
  z & (θor2 ⊻ onetwo) ⥅ y
  @assert is_valid(c)
  c
end
