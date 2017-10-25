"Returns a domain_error arrow of the inverse of the given arrow with the index of
an additional port equal to the sum (or other combination) of all the domain losses."
function domain_ovrl(arr::CompArrow)
  invarr = invert(arr)
  domainϵ = domain_error(invarr)

  dmloss = CompArrow(:dmloss)
  domain_sarr = add_sub_arr!(dmloss, domainϵ)
  foreach(link_to_parent!, ▹(domain_sarr))
  foreach(link_to_parent!, ◃(domain_sarr))
  ϵports = ◃(domain_sarr, is(ϵ))
  index = length(◂(domainϵ)) + 1
  ovrl_loss = add_port_like!(dmloss, ◂(dmloss, is(ϵ), 1))

  # FIXME: use an array addition arrow if/when made.
  port_to_add = ϵports[1]
  for i = 2:length(ϵports)
    add = add_sub_arr!(dmloss, AddArrow())
    link_ports!(port_to_add, (add, 1))
    link_ports!(ϵports[i], (add, 2))
    port_to_add = ◃(add, 1)
  end
  port_to_add ⥅ ovrl_loss
  aprx_totalize!(dmloss)
  dmloss, index
end

"Verify domain_loss and id_loss can be zero using pgf."
function verify_loss(arr::CompArrow, inputs=rand(length(▸(arr))), ϵtol=1e-10)
  domain_loss, i = domain_ovrl(arr)
  pgfarr = pgf(arr)

  outs = pgfarr(inputs...)
  loss_values = domain_loss(outs...)
  isapprox(loss_values[i], 0, atol=ϵtol) || throw(ArgumentError("Domain loss with pgf values should be 0, is $loss_values instead."))

  invarr = invert(arr)
  idloss = id_loss(arr, invarr)
  loss_values = idloss(outs...)
  isapprox(loss_values[1], 0, atol=ϵtol) || throw(ArgumentError("Id loss with pgf values should be 0, is $loss_values instead."))
end

"Runs optimization on the specified domain/id loss and (for now) returns the
loss after optimization with both the actual outputs and the optimized results."
function verify_optim(arr::CompArrow, inputs=rand(length(▸(arr, !is(θp)))), opt="domain")
  # the given arrow shouldn't have parametric ports
  length(inputs) == length(▸(arr, !is(θp))) || throw(ArgumentError("Incorrect number of inputs given."))
  outs = arr(inputs...)
  invarr = invert(arr)
  aprx_totalize!(invarr)
  optimizer, index = domain_ovrl(arr)
  if opt == "id"
    optimizer = id_loss(arr, invarr)
    index = 1
  end
  j=0
  function savedata(data):
    println("Step number $j...")
    j += 1
  end
  init = [outs..., rand(length(▸(optimizer, is(θp))))...]
  error, argmin = optimize(optimizer, ▸(optimizer, is(θp)), ◂(optimizer, index), init;
                            callbacks=[])
  println("The optimized $opt loss is $error.")
  opt_inputs = invarr(outs..., argmin...)
  opt_outs = arr(opt_inputs...)
  error, outs, opt_outs
end
#
# "Plots the optimization loss vs iteration step for the given arrow
# where the optimization method is specified by the given type."
# function plot_optim(arr::CompArrow, n_trials::Integer, opt="id")
# #
# add = CompArrow(:test, [:x, :y], [:z])
# x, y, z = ⬨(add)
# x * y + x ⥅ z
# add
# verify_optim(add)
#
