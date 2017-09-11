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
    if (i % 100 == 0)
      ExampleArrows.drawscene(pointmat, obstacles, inputs...)
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
