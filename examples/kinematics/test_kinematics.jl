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
  fwd = fwd_2d_linkage_obs(nlinks)
  # fwd = Arrows.TestArrows.xy_plus_x_arr()
  # fwd = test_two_op()
  @show invarr = approx_invert(fwd)
  invloss = Arrows.iden_loss(fwd, invarr)
  @show nparams = length(filter(Arrows.is_parameter_port, in_ports(invloss)))
  @show invlossjl = Arrows.julia(invloss)
  @show invarrjl = Arrows.julia(invarr)

  inputs = [1.0, 1.0]
  i = 0
  obstacles = [ExampleArrows.Circle([0.5, 0.5], 0.3),
               ExampleArrows.Circle([0.0, 0.5], 0.3)]
  function invlossf(θs::Vector, grad::Vector)
    loss = invlossjl(inputs..., θs...)[1]
    angles = invarrjl(inputs..., θs...)
    pointmat = ExampleArrows.vertices([angles...])
    if (i % 100 == 0)
      ExampleArrows.drawscene(pointmat, obstacles, inputs...)
    end
    i += 1
    loss
    # @show θs
    # @show loss
  end

  Arrows.Analysis.hist_compare(fwd, invlossf, nparams; nsamples=100)
end

Arrows.Analysis.hist_compare


analyze_kinematics(3)|
nlinks = 3
fwd = fwd_2d_linkage_obs(nlinks)

pls = plain_arrows()

# function ok(fwd)
#   invarr = Arrows.approx_invert(fwd)
#   invloss = Arrows.iden_loss(fwd, invarr)
#   nparams = length(filter(Arrows.is_parameter_port, in_ports(invloss)))
#   invlossjl = Arrows.julia(invloss)
#   invarrjl = Arrows.julia(invarr)
#   invloss, invlossjl
# end
#
# for (j, fwd) in enumerate(Arrows.TestArrows.plain_arrows())
#   nin = num_out_ports(fwd)
#   inputs = rand(nin)
#   invloss, invlossjl = ok(fwd)
#   nparams = num_in_ports(invloss) - nin
#   params = rand(nparams)
#   for i = 1:10
#     @show invlossjl(inputs..., params...)
#     invloss, invlossjl = ok(fwd)
#     fwd = Arrows.TestArrows.plain_arrows()[j]
#   end
# end
#
# invloss

θs = [0.962056, 1.73892, -0.172778, 0.36381, 0.505187, 0.308938, 0.242637, 0.00480574, 0.82769, 0.97051, 0.490989, 0.645429, 0.188202, 0.0895715, 0.724754, 3.03171, 0.52669, 0.856996, 0.925592, 1.67078, 1.12515, 0.492938, 0.219698, 0.724886, 0.883057, 0.515478, 0.205461, 0.255325, 0.0596359, 2.45288, 0.602339, 0.473573, 0.522505, 0.430647, 0.878401, -0.196298]
