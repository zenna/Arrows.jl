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

"Inverse Or"
function inv_or()
  c = CompArrow(:inv_or, [:z, :θor1, :θor2], [:x, :y])
  z, θor1, θor2, x, y = ⬨(c)
  addprop!(θp, θor1)
  addprop!(θp, θor2)
  onetwo = !(θor1 & θor2)
  z & (θor1 ⊻ onetwo) ⥅ x
  z & (θor2 ⊻ onetwo) ⥅ y
  @assert is_wired_ok(c)
  c
end
