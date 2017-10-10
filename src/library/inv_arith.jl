"Inverse Addition"
function inv_add()
  c = CompArrow(:inv_add, [:z, :θadd], [:x, :y])
  z, θ = ▸(c)
  x, y = ◂(c)
  addprop!(θp, θ)
  subtract = add_sub_arr!(c, SubtractArrow())
  link_ports!(z, (subtract, 1))
  link_ports!(θ, (subtract, 2))
  link_ports!((subtract, 1), x)
  link_ports!(θ, y)
  c
end

"Inverse Subtraction"
function inv_sub()
  carr = CompArrow(:inv_sub, [:z, :θsub], [:x, :y])
  z, θ, x, y = ⬨(carr)
  addprop!(θp, deref(θ))
  (z + θ) ⥅ x
  θ ⥅ y
  carr
end

"Inverse multiplication"
function inv_mul()
  c = CompArrow(:inv_mul, [:z, :θmul], [:x, :y])
  z, θ = ▸(c)
  x, y = ◂(c)
  div = add_sub_arr!(c, DivArrow())
  addprop!(θp, θ)
  link_ports!(z, (div, 1))
  link_ports!(θ, (div, 2))
  link_ports!((div, 1), x)
  link_ports!(θ, y)
  c
end
