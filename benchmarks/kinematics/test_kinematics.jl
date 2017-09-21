using NamedTuples

"Example scene"
function example_scene(path_length::Integer)
  angles = rand(path_length) * 2π
  obstacles = [Circle([0.5, 1.5], 0.7)
               Circle([2.0, 1.8], 0.7)]
  x_target = 2.4
  y_target = 1.5
  @NT(angles = angles,
      obstacles = obstacles,
      x_target = x_target,
      y_target = y_target)
end

function test_draw()
  angles, obstacles, x_target, y_target = example_scene(3)
  drawscene(angles, obstacles, x_target, y_target)
end

function test_invert()
  arr = fwd_2d_linkage_obs(3)
  invarr = Arrows.aprx_invert(arr)
  num_in_ports(invarr)
  invarr(1.0, 1.0, rand(18)...)
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
  obstacles = [BenchmarkArrows.Circle([0.5, 0.5], 0.3),
               BenchmarkArrows.Circle([0.0, 0.5], 0.3)]
  function invlossf(θs::Vector, grad::Vector)
    loss = invlossjl(inputs..., θs...)[1]
    angles = invarrjl(inputs..., θs...)
    pointmat = BenchmarkArrows.vertices([angles...])
    if (i % 100 == 0)
      BenchmarkArrows.drawscene(pointmat, obstacles, inputs...)
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

eval_theta()

Arrows.mean_errors!
nlinks = 2
fwd = fwd_2d_linkage_obs(nlinks)
inputs = ones(num_out_ports(fwd))
invarr = aprx_invert(fwd)
