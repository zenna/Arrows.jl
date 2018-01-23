using Arrows
using Arrows.TestArrows
using Base.Test


function test_sym_gather_inv()
  indices = [[0, 1] [2, 2]]
  params = reshape(collect(1:9), (3,3));
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
  apprx = Arrows.aprx_totalize(inv_c << wirer);
  parts = vcat(1:6, [9,]);
  z = f(params)
  inverted_params = apprx(z, parts)
  @test sum(abs.(inverted_params - params)) == 0
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
  apprx = Arrows.aprx_totalize(inv_c << wirer);
  parts = vcat(1:13, 15:21, 23:24, 26:45, 47:100);
  z = f(params)
  θm = [46, 14]
  θa = z ./(θm +1)
  inverted_params = apprx(z, parts, θm, θa)
  @test sum(abs.(inverted_params - params)) == 0
end

function test_sym_gather_inv_log()
  indices = [[1, 4] [2, 2]]
  indices2 = [[5, 3] [4, 1]]
  params = reshape(collect(1:100), (10,10));
  shape = size(params)
  function f(params)
    a = gather_nd(params, indices, shape)
    b = gather_nd(params, indices2, shape)
    b .* log(a)
  end
  c = CompArrow(:c, [:x], [:z])
  x, = ▹(c)
  f(x) ⥅ ◃(c,1)
  c = Arrows.duplify!(c)
  inv_c = Arrows.invert(c)
  wirer, info = Arrows.solve(inv_c);
  apprx = Arrows.aprx_totalize(inv_c << wirer);
  parts = vcat(1:13, 15:21, 23:24, 26:45, 47:100);
  z = f(params)
  θm = log.([22, 25])
  inverted_params = apprx(z, parts, θm)
  @test sum(abs.(inverted_params - params)) < 0.000001
end

function test_sym_gather_inv_log_special()
  indices = [[1, 4] [2, 2]]
  indices2 = [[5, 3] [4, 1]]
  params = reshape(collect(1:100), (10,10));
  shape = size(params)
  c = CompArrow(:c, [:x], [:z])
  two, = ◃(add_sub_arr!(c, SourceArrow(2)))
  function f(params, two)
    a = gather_nd(params, indices, shape)
    log(a) * two .+ log(a)
  end
  x,  = ▹(c)
  f(x, bcast(two)) ⥅ ◃(c,1)
  c = Arrows.duplify!(c)
  inv_c = Arrows.invert(c)
  z = f(params, 2)
  ▹z = ▹(inv_c, 1)
  init_size = ▹z=>Arrows.AbValues(:size=>Arrows.Size(size(z)))
  wirer, info = Arrows.solve(inv_c, SprtAbValues(init_size));
  apprx = Arrows.aprx_totalize(inv_c << wirer);
  parts = vcat(1:21, 23:24, 26:100);

  θm = log.([22, 25]);
  inverted_params = apprx(z, parts, θm);
  @test sum(abs.(inverted_params - params)) < 0.000001
end


function test_sym_special()
  indices = [[1, 4] [2, 2]]
  indices2 = [[5, 3] [4, 1]]
  params = reshape(collect(1:100), (10,10));
  shape = size(params)
  function f(params)
    a = gather_nd(exp(params), indices, shape)
    b = gather_nd(params, indices2, shape)
    b .* log(a)
  end
  c = CompArrow(:c, [:x], [:z])
  x, = ▹(c)
  f(x) ⥅ ◃(c,1)
  inv_c = c |> Arrows.duplify |> Arrows.invert
  ▹z = ▹(inv_c, 1)
  z = f(params)
  init_size = ▹z=>Arrows.AbValues(:size=>Arrows.Size(z |> size))
  wirer, info = Arrows.solve(inv_c, SprtAbValues(init_size));
  apprx = Arrows.aprx_totalize(inv_c << wirer);
  parts = exp.(vcat(1:13, 15:21, 23:24, 26:45, 47:100));
   θm = [22, 25]
  inverted_params = apprx(z, parts, θm)
  @test sum(abs.(inverted_params - params)) < 0.000001
end


## foreach(test_sym, TestArrows.plain_arrows())

## preds = Arrows.constraints(invert(TestArrows.weird_arr()))

test_sym_gather_inv_mult()
test_sym_gather_inv()
test_sym_gather_inv_log()
test_sym_gather_inv_log_special()
test_sym_special()

# Symbolic Execution on simple arrows
function pre_test(arr::Arrow)
  println("Testing symbolic execution of arrow ", name(arr))
  arr
end

foreach(Arrows.all_constraints ∘ pre_test ∘ invert, plain_arrows())
