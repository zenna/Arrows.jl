using Base.Test
using Arrows

function test_assert()
  carr = CompArrow(:xyx20, [:x, :y], [:z])
  x, y, z = sub_ports(carr)
  a = (2x + y)
  assert!(y > 100)
  a ⥅ z
  carr
end

function test_invert_assert()
  carr = test_assert()
  invert(carr)
end

function test_invert_assert_optim()
  fwdarr = test_assert()
  invarr = approx_invert(fwdarr)
  invloss = iden_loss(fwdarr, invarr)
  invlossjl = julia(invloss)
  invarrjl = julia(invarr)
  nparams = num_in_ports(invloss) - 1
  z = 5.0
  function invlossf(θs::Vector, grad::Vector)
    loss = invlossjl(z, θs...)[1]
  end

  hist_compare(fwdarr, invlossf, nparams; nsamples=1000)
end

test_assert()
test_invert_assert()
