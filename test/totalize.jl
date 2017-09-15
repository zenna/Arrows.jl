using Arrows
using Base.Test

function test_aprx_errors()
  arr = SqrtArrow()
  arr_w_errors = aprx_errors(arr)
  total_arr = aprx_totalize(arr_w_errors)
  total_arr(-2.0)
end

arr = SqrtArrow()
arr = wrap(arr)
arr_w_errors = aprx_errors(arr)
arr_w_errors


is_error_port.(inner_sub_ports(arr_w_errors))
arr_w_errors
total_arr = aprx_totalize(arr_w_errors)

set_parameter_port!(in_port(AddArrow(), 1))
AddArrow()
test_aprx_errors()

Should you be able to change port properties of a primitive arrow ?
No
- Wrap it in a comp if you need tht
-

Yes
Why not?


θ ∧ o[1:end]

ϵ! = set_error_port!

\l

Θ = 3
θ

set_port

p.o.(1)
i(1)

arr = SqrtArrow()
arr_w_errors = aprx_errors(arr)
total_arr = aprx_totalize(arr_w_errors)
total_arr(-2.0)

function test_δinterval()
  carr = CompArrow(:tcarr, [:x], [:y])
  x, y = sub_ports(carr)
  zz = δinterval(x, -1, 1)
  zz ⥅ y
  @test carr(0.5)[1] == 0
  @test carr(-4)[1] > 0
end

test_δinterval()
