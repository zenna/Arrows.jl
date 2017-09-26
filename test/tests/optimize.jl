using Arrows
using Base.Test

function test_optimize(fwd)
  invarr = aprx_invert(fwd)
  invarr = Arrows.meanerror(invarr)
  init = [rand() for p in ▸(invarr)]
  over = ▸(invarr, is(θp))
  ϵprt = ◂(invarr, is(ϵ), 1)

  function dataget(data)
    data.loss
  end
  θ_optim = optimize(invarr, over, ϵprt, init; callbacks = [dataget])
end

test_optimize(Arrows.TestArrows.xy_plus_x_arr())
