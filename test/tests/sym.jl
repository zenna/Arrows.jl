using Arrows
using Arrows.TestArrows
using Base.Test


function test_sym_gather_inv()
  indices = [[1, 4] [2, 2]]
  params = reshape(collect(1:100), (10,10));
  shape = size(params)
  function f(params)
    return gather_nd(params, indices, shape)
  end
  c = CompArrow(:c, [:x], [:z])
  x, = ▹(c)
  f(x) ⥅ ◃(c,1)
  c = Arrows.duplify!(c)
  inv_c = Arrows.invert(c)
  wirer, info = Arrows.solve(inv_c);
  wired = Arrows.connect_target(wirer, inv_c);
  apprx = Arrows.aprx_totalize(wired);
end

function test_sym_gather_inv_mult()
  indices = [[1, 4] [2, 2]]
  indices2 = [[5, 3] [4, 1]]
  params = reshape(collect(1:100), (10,10));
  shape = size(params)
  function f(params)
    a = gather_nd(params, indices, shape)
    b = gather_nd(params, indices2, shape)
    (a .* b) .+ a
  end
  c = CompArrow(:c, [:x], [:z])
  x, = ▹(c)
  f(x) ⥅ ◃(c,1)
  c = Arrows.duplify!(c)
  inv_c = Arrows.invert(c)
  wirer, info = Arrows.solve(inv_c);
  wired = Arrows.connect_target(wirer, inv_c);
  apprx = Arrows.aprx_totalize(wired);
  parts = vcat(1:13, 15:21, 23:24, 26:45, 47:100);
  z = f(params)
  θm = [46, 14]
  θa = z ./(θm +1)
  inverted_params = apprx(z, parts, θm, θa)
  @test sum(abs.(inverted_params - params)) == 0
end


## foreach(test_sym, TestArrows.plain_arrows())

## preds = Arrows.constraints(invert(TestArrows.weird_arr()))

test_sym_gather_inv_mult()
