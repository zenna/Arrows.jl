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
  num_in_ports(invarr)
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
  invarrwerros = aprx_error(invarr)
  totalinvarr = Arrows.aprx_totalize(invarrwerros)
  meanerror(totalinvarr)
end

function test(nlinks=4)
  invarr = invlossarr(nlinks)
  invθ▸ = ▸(invarr, isθ)
  nparams = length(▸(invarr, isθ))
  init = [1.0, 1.0, rand(nparams)...]
  @assert length(init) == length(▸(invarr))

  i = 0
  function drawarm(data)
    inputs = [1.0, 1.0]
    angles = data.output[1:end-1]
    obstacles = [BenchmarkArrows.Circle([0.5, 0.5], 0.3),
                 BenchmarkArrows.Circle([0.0, 0.5], 0.3)]
    pointmat = BenchmarkArrows.vertices([angles...])
    if (i % 100 == 0)
      BenchmarkArrows.drawscene(pointmat, obstacles, inputs...)
    end
    i += 1
  end

  optimize(invarr, invθ▸, ◂(invarr, isϵ, 1), init; callbacks = [drawarm])
end

test()
