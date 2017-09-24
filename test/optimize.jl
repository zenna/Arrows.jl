using Arrows
using Base.Test

function test_optimize(fwd)
  invarr = aprx_invert(fwd)
  invarr = meanerror(invarr)
  init = vcat([1.0], [rand() for p in ▸(invarr, isθ)])
  over = ▸(invarr, isθ)
  ϵprt = ◂(invarr, isϵ, 1)

  function dataget(data)
    data.loss
  end
  optimize(invarr, over, ϵprt, init; callbacks = [dataget])
end
