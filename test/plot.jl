function test_xyx()
  fwd = TestArrows.xy_plus_x_arr()
  invloss = iden_loss(fwd, approx_invert(fwd))
  z = 10.0
  invlossf(x::Vector, grad::Vector) = invloss(z, x...)[1]
  hist_compare(fwd, invlossf, 10.0)
end

function analyze_kinematics(nlinks = 3)
  fwd = ExampleArrows.fwd_2d_linkage(nlinks)
  fwdpoints = ExampleArrows.fwd_2d_linkage_points(nlinks)
  invarr = approx_invert(fwd)
  invloss = iden_loss(fwd, invarr)
  nparams = num_in_ports(invloss) - 2
  x, y = 1.0, 1.0
  function invlossf(θs::Vector, grad::Vector)
    loss = invloss(x, y, θs...)[1]
    angles = invarr(x, y, θs...)
    points = fwdpoints(angles...)
    pointmat = reshape(Vector([points...]), (2, nlinks))
    @show angles
    @show pointmat
    # fwd_2d_linkage_points(nlinks)
    ExampleArrows.drawscene(pointmat, [], x, y)
    @show loss
  end

  hist_compare(fwd, invlossf, 6; nsamples=1000)
end
