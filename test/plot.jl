function test_xyx()
  fwd = TestArrows.xy_plus_x_arr()
  invloss = iden_loss(fwd, aprx_invert(fwd))
  z = 10.0
  invlossf(x::Vector, grad::Vector) = invloss(z, x...)[1]
  hist_compare(fwd, invlossf, 10.0)
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
  fwd = ExampleArrows.fwd_2d_linkage(nlinks)
  @show invarr = aprx_invert(fwd)
  invloss = iden_loss(fwd, invarr)
  nparams = num_in_ports(invloss) - 2
  @show invlossjl = julia(invloss)
  @show invarrjl = julia(invarr)

  x, y = 1.0, 1.0
  i = 0
  obstacles = [ExampleArrows.Circle([0.5, 0.5], 0.3)]
  function invlossf(θs::Vector, grad::Vector)
    loss = invlossjl(x, y, θs...)[1]
    angles = invarrjl(x, y, θs...)
    pointmat = vertices([angles...])
    if i % 100 == 0
      ExampleArrows.drawscene(pointmat, obstacles, x, y)
    end
    i += 1
    loss
  end

  hist_compare(fwd, invlossf, nparams; nsamples=1000)
end

analyze_kinematics(4)
