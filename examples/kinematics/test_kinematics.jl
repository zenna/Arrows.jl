### Testing Drawing
function example_data_angles(path_length::Integer)
  angles = rand(path_length) * 2π
  obstacles = [Circle([0.5, 1.5], 0.7)
               Circle([2.0, 1.8], 0.7)]
  x_target = 2.4
  y_target = 1.5
  angles, obstacles, x_target, y_target
end

function test_draw()
  angles, obstacles, x_target, y_target = example_data_angles(3)
  drawscene(angles, obstacles, x_target, y_target)
end

function test_invert()
  arr = fwd_2d_linkage_obs(3)
  invarr = Arrows.approx_invert(arr)
  num_in_ports(invarr)
  invarr(1.0, 1.0, rand(18)...)
end

"Compute vertices from angles"
function vertices(angles::Vector)
  xs = [0.0]
  ys = [0.0]
  total = 0.0
  sin_total = 0.0
  cos_total = 0.0
  for i = 1:length(angles)
    total = total + angles[i]
    sin_total += sin(total)
    xs = vcat(xs, [sin_total])
    cos_total += cos(total)
    ys = vcat(ys, [cos_total])
  end
  permutedims(hcat(xs, ys), (2, 1))
end

function analyze_kinematics(nlinks = 3)
  fwd = fwd_2d_linkage(nlinks)
  # fwd = Arrows.TestArrows.xy_plus_x_arr()
  # fwd = test_two_op()
  invarr = Arrows.approx_invert(fwd)
  @show invarr = approx_invert(fwd)
  invloss = Arrows.iden_loss(fwd, invarr)
  @show nparams = length(filter(Arrows.is_parameter_port, in_ports(invloss)))
  @show invlossjl = Arrows.julia(invloss)
  @show invarrjl = Arrows.julia(invarr)

  inputs = [1.0, 1.0]
  i = 0
  obstacles = [ExampleArrows.Circle([0.5, 0.5], 0.3)]
  function invlossf(θs::Vector, grad::Vector)
    loss = invlossjl(inputs..., θs...)[1]
    angles = invarrjl(inputs..., θs...)
    pointmat = ExampleArrows.vertices([angles...])
    if (i % 100 == 0) && (loss < 0.001)
      ExampleArrows.drawscene(pointmat, obstacles, inputs)
    end
    i += 1
    @show θs
    @show loss
  end

  Arrows.hist_compare(fwd, invlossf, nparams; nsamples=100)
end

function test_two_op()
  carr = CompArrow(:xyab, [:x, :y], [:a, :b])
  x, y, a, b = sub_ports(carr)
  z = x + y
  c = y * z
  c ⥅ a
  z ⥅ b
  carr
end


analyze_kinematics(2)


nlinks = 2

θs = [1.00003, 1.00008]
inputs = [1.0, 1.0]
fwd = fwd_2d_linkage(nlinks); fwd(2.3, 1.0) ; @show invarr = Arrows.approx_invert(fwd)
fwd = Arrows.TestArrows.xy_plus_x_arr()
fwd = test_two_op()

invarr = Arrows.approx_invert(fwd)
invloss = Arrows.iden_loss(fwd, invarr)

fwd(invarr(inputs..., θs...)...)
foreach(println, Arrows.links(invloss))
Arrows.compile(invloss)






@show nparams = num_in_ports(invloss) - 1
@show invlossjl = Arrows.julia(invloss)
@show invarrjl = Arrows.julia(invarr)
x, y = 1.0, 1.0
function invlossf(θs::Vector, grad::Vector)
  loss = invlossjl(x, θs...)[1]
  angles = invarrjl(x, θs...)
  # pointmat = ExampleArrows.vertices([angles...])
  # ExampleArrows.drawscene(pointmat, obstacles, x, y)
  loss
end
invlossf([1.00007, 0.371663], [])




function name_to_stack_to_mean(val_name_to_stack_to_mean_1, val_name_to_stack_to_mean_2, val_name_to_stack_to_mean_3, val_name_to_stack_to_mean_4)
    (val_1980_5, val_1980_6, val_1980_7, val_1980_8) = namea(val_name_to_stack_to_mean_1, val_name_to_stack_to_mean_2, val_name_to_stack_to_mean_3, val_name_to_stack_to_mean_4)
    (val_1979_5,) = stack_to_mean(val_1980_5, val_1980_6, val_1980_7, val_1980_8)
    return (val_1979_5,)
end
function stack_to_mean(val_stack_to_mean_1, val_stack_to_mean_2, val_stack_to_mean_3, val_stack_to_mean_4)
    (val_1977_3, val_1977_6) = stack(val_stack_to_mean_1, val_stack_to_mean_2, val_stack_to_mean_3, val_stack_to_mean_4)
    (val_1976_3,) = mean(val_1977_3, val_1977_6)
    return (val_1976_3,)
end
function stack(val_stack_1, val_stack_2, val_stack_4, val_stack_5)
    (val_1974_3,) = adiff(val_stack_1, val_stack_2)
    (val_1975_3,) = adiff(val_stack_4, val_stack_5)
    return (val_1974_3, val_1975_3)
end
function adiff(val_adiff_1, val_adiff_2)
    (val_1969_3,) = to_sqr(val_adiff_1, val_adiff_2)
    (val_1968_2,) = sqrt(val_1969_3)
    return (val_1968_2,)
end
function to_sqr(val_to_sqr_1, val_to_sqr_2)
    (val_1967_3,) = val_to_sqr_1 - val_to_sqr_2
    (val_1966_2,) = sqr(val_1967_3)
    return (val_1966_2,)
end
function namea(val_name_1, val_name_2, val_name_3, val_name_4)
    (val_1978_5, val_1978_6) = inv_xyab_to_xyab(val_name_1, val_name_2, val_name_3, val_name_4)
    return (val_1978_5, val_1978_6, val_name_1, val_name_2)
end
function inv_xyab_to_xyab(val_inv_xyab_to_xyab_1, val_inv_xyab_to_xyab_2, val_inv_xyab_to_xyab_3, val_inv_xyab_to_xyab_4)
    (val_1965_1, val_1965_2) = inv_xyab(val_inv_xyab_to_xyab_1, val_inv_xyab_to_xyab_2, val_inv_xyab_to_xyab_3, val_inv_xyab_to_xyab_4)
    (val_1964_3, val_1964_4) = xyab(val_1965_1, val_1965_2)
    return (val_1964_3, val_1964_4)
end
function xyab(val_xyab_1, val_xyab_2)
    (val_1948_3,) = val_xyab_1 + val_xyab_2
    (val_1949_3,) = val_xyab_2 * val_1948_3
    return (val_1949_3, val_1948_3)
end
function inv_xyab(val_inv_xyab_3, val_inv_xyab_4, val_inv_xyab_5, val_inv_xyab_6)
    (val_1961_3, val_1961_4) = inv_mula(val_inv_xyab_3, val_inv_xyab_6)
    (val_1962_3,) = mean(val_inv_xyab_4, val_1961_4)
    (val_1959_3, val_1959_4) = inv_add(val_1962_3, val_inv_xyab_5)
    (val_1963_3,) = mean(val_1959_4, val_1961_3)
    return (val_1959_3, val_1963_3)
end
function inv_add(val_inv_add_1, val_inv_add_2)
    (val_1958_3,) = val_inv_add_1 - val_inv_add_2
    return (val_1958_3, val_inv_add_2)
end
function inv_mula(val_inv_mula_1, val_inv_mula_2)
    (val_1960_3,) = val_inv_mula_1 / val_inv_mula_2
    return (val_1960_3, val_inv_mula_2)
end


















Arrows.hist_compare()
