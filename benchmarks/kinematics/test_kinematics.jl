using NamedTuples
import Arrows: is_error_port, loose, link_to_parent!, meanerror
using Arrows
using Arrows.BenchmarkArrows

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
  invarr(1.0, 1.0, rand(18)...)
end

function eval_theta(nlinks=2)
  fwd = fwd_2d_linkage_obs(nlinks)
  inputs = ones(num_out_ports(fwd))
  invarr = aprx_invert(fwd)
  invloss = Arrows.id_loss(fwd, invarr)
  nparams = length(filter(Arrows.is_parameter_port, in_ports(invloss)))
  invlossjl = Arrows.julia(invloss)
  invarrjl = Arrows.julia(invarr)
  invloss, invlossjl
end

"Generate the inverse arrow with loss"
function invlossarr(nlinks)
  fwd = fwd_2d_linkage(nlinks)
  invarr = invert(fwd)
  invarrwerros = domain_error(invarr)
  totalinvarr = Arrows.aprx_totalize(invarrwerros)
  meanerror(totalinvarr)
end

function test(nlinks=3)
  fwd = fwd_2d_linkage(nlinks)
  allϵinvarr = aprx_invert(fwd)
  invarr = meanerror(allϵinvarr)
  invθ▸ = ▸(invarr, is(θp))
  nparams = length(▸(invarr, is(θp)))
  init = [1.0, 1.0, rand(nparams)...]
  @assert length(init) == length(▸(invarr))

  # Plotting
  ◂ϵids = findn(is(ϵ).(◂(allϵinvarr)))
  @show ◂ϵids
  allϵinvarrjl = julia(allϵinvarr)
  domain_losses = Matrix{Float64}(length(◂ϵids), 0)
  j = 0
  function analysis(data)
    output = allϵinvarrjl(data.input...)
    ◂ϵ = [output...][◂ϵids]
    domain_losses = [domain_losses ◂ϵ]
    Arrows.Analysis.plot_domain_loss(domain_losses)
    Plots.savefig("plot$(j).png")
    j += 1
  end

  i = 0
  function drawarm(data)
    inputs = [1.0, 1.0]
    angles = data.output[1:end-1]
    obstacles = [BenchmarkArrows.Circle([0.5, 0.5], 0.3),
                 BenchmarkArrows.Circle([0.0, 0.5], 0.3)]
    pointmat = BenchmarkArrows.vertices([angles...])
    if (i % 2 == 0)
      BenchmarkArrows.drawscene(pointmat, obstacles, inputs...)
    end
    @show i += 1
  end

  optimize(invarr, invθ▸, ◂(invarr, is(ϵ), 1), init;
           callbacks = [analysis, drawarm])
end

test()
using Plots
Arrows.Analysis.plot_domain_loss(rand(10,10))

function test_pgf(arr)
  randin = rand(length(▸(arr)))
  pgfarr = Arrows.pgf(arr)
  pgfout = pgfarr(randin...)
  invarr = invert(arr)
  out = invarr(pgfout...)
  all(map(≈, randin, out))
end

arr = fwd_2d_linkage(3)
test_pgf(arr)
