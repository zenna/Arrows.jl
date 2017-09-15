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
  invarr = Arrows.aprx_invert(arr)
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
  inputs = ones(num_out_ports(fwd))
  # fwd = Arrows.TestArrows.xy_plus_x_arr()
  # fwd = test_two_op()
  @show invarr = aprx_invert(fwd)
  invloss = Arrows.iden_loss(fwd, invarr)
  @show nparams = length(filter(Arrows.is_parameter_port, in_ports(invloss)))
  @show invlossjl = Arrows.julia(invloss)
  @show invarrjl = Arrows.julia(invarr)

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

function eval_theta(nlinks=2)
  fwd = fwd_2d_linkage_obs(nlinks)
  inputs = ones(num_out_ports(fwd))
  invarr = aprx_invert(fwd)
  invloss = Arrows.iden_loss(fwd, invarr)
  nparams = length(filter(Arrows.is_parameter_port, in_ports(invloss)))
  invlossjl = Arrows.julia(invloss)
  invarrjl = Arrows.julia(invarr)
  invloss, invlossjl
end

# arr, jl = eval_theta(2)  
# jl
#
# arr
#
# analyze_kinematics(2)
#
# θs = [1.47326, 0.356264, 1.21657, 0.934543, 0.626135, 0.119368, 0.863315, 0.0141938, 0.833309, 0.786484, 0.860195, 0.134759, 0.810281, 0.0467791, 0.483127, 0.68971, 0.285376, 0.399064]
#
#
# jl(1.0, 1.0, θs...)
# length(θs)
# num_in_ports(arr)
# function ok(fwd)
#   invarr = Arrows.aprx_invert(fwd)
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
