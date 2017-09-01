"Inverse Addition"
function inv_add()
  c = CompArrow{2, 2}(:inv_add, [:z, :θ], [:x, :y])
  z, θ = in_ports(c)
  x, y = out_ports(c)
  subtract = add_sub_arr!(c, SubtractArrow())
  link_ports!(z, (subtract, 1))
  link_ports!(θ, (subtract, 2))
  link_ports!((subtract, 1), x)
  link_ports!(θ, y)
  c
end

"Inverse multiplication"
function inv_mul()
  c = CompArrow{2, 2}(:inv_mul, [:z, :θ], [:x, :y])
  z, θ = in_ports(c)
  x, y = out_ports(c)
  div = add_sub_arr!(c, DivArrow())
  link_ports!(z, (div, 1))
  link_ports!(θ, (div, 2))
  link_ports!((div, 1), x)
  link_ports!(θ, y)
  c
end
