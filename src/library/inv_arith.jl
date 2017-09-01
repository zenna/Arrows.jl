function inv_add()
  c = CompArrow{2, 2}(:inv_add)
  z, θ = in_ports(c)
  x, y = out_ports(c)
  subtract = add_sub_arr!(c, SubtractArrow())
  link_ports!(c, z, (subtract, 1))
  link_ports!(c, θ, (subtract, 2))
  link_ports!(c, (subtract, 1), x)
  link_ports!(c, θ, y)
  c
end

"Inverse multiplication"
function inv_mul()
  c = CompArrow{2, 2}(:inv_mul)
  z, θ = in_ports(c)
  x, y = out_ports(c)
  div = add_sub_arr!(c, DivArrow())
  link_ports!(c, z, (div, 1))
  link_ports!(c, θ, (div, 2))
  link_ports!(c, (div, 1), x)
  link_ports!(c, θ, y)
  c
end
