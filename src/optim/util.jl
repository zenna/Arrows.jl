"Returns a domain_error arrow of the inverse of the given arrow with the index of
an additional port equal to the sum (or other combination) of all the domain losses."
function domain_ovrl(arr::CompArrow, newinv=inv)
  domainϵ = aprx_invert(arr, newinv)
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
  #aprx_totalize!(dmloss)
  dmloss, index
end

"x: -> δ(arr(x), outs)"
function naive_loss(arr::CompArrow, yvals)
  length(yvals) == length(◃(arr)) || throw(ArgumentError("Invalid length for given outs."))
  naive = CompArrow(Symbol(:naive_loss_, name(arr)))
  sarr = add_sub_arr!(naive, arr)
  foreach(link_to_parent!, ▹(sarr))
  foreach(link_to_parent!, ◃(sarr))
  loss = add_port_like!(naive, ◂(naive, 1))
  addprop!(ϵ, loss)
  out_vals = []
  for i = 1:length(yvals)
    src = add_sub_arr!(naive, SourceArrow(yvals[i]))
    push!(out_vals, ◃(src, 1))
  end
  out_vals = Array{Arrows.SubPort}(out_vals)
  out = sumδ(◃(sarr), out_vals)
  out ⥅ loss
  index = length(◂(naive))
  naive, index
end

"Verify domain_loss and id_loss can be zero using pgf."
function verify_loss(arr::CompArrow, inputs=rand(length(▸(arr))), ϵtol=1e-10)
  invarr = invert(arr)
  domain_loss, i = domain_ovrl(arr, invarr)
  pgfarr = pgf(arr)

  outs = pgfarr(inputs...)
  loss_values = domain_loss(outs...)
  isapprox(loss_values[i], 0, atol=ϵtol) || throw(ArgumentError("Domain loss with pgf values should be 0, is $loss_values instead."))

  idloss = id_loss(arr, invarr)
  loss_values = idloss(outs...)
  isapprox(loss_values[1], 0, atol=ϵtol) || throw(ArgumentError("Id loss with pgf values should be 0, is $loss_values instead."))
end

"Runs optimization on the specified domain/id loss and (for now) returns the
loss after optimization with both the actual outputs and the optimized results."
function verify_optim(arr::CompArrow; inputs=rand(length(▸(arr, !is(θp)))), opt="domain")
  # the given arrow shouldn't have parametric ports
  length(inputs) == length(▸(arr, !is(θp))) || throw(ArgumentError("Incorrect number of inputs given."))
  outs = arr(inputs...)
  invarr = invert(arr)
  aprx_totalize!(invarr)
  optimizer, index = domain_ovrl(arr, invarr)
  if opt == "id"
    optimizer, index = id_loss(arr, invarr), 1
  end
  init = [outs..., rand(length(▸(optimizer, is(θp))))...]
  error, argmin = optimize(optimizer, ▸(optimizer, is(θp)), ◂(optimizer, index), init)
  println("The optimized $opt loss is $error.")
  opt_inputs = invarr(outs..., argmin...)
  opt_outs = arr(opt_inputs...)
  error, outs, opt_outs
end

"Plots (returns) the domain/id log-loss vs iteration step for the given arrow
where the optimization methods are: domain, id, naive."
function plot_optim(arr::CompArrow, n_trials::Integer, newinv=inv)
  inputs=rand(length(▸(arr, !is(θp))))
  outs = arr(inputs...)
  dmloss, i = domain_ovrl(arr, newinv)
  invarr = invert(arr, newinv)
  aprx_totalize!(invarr)
  idloss = id_loss(arr, invarr)
  naiveloss, j = naive_loss(arr, outs)

  # domain_loss optimization
  domain_dm = []
  domain_id = []
  function savedomain(data)
    dm_error = dmloss(data.input...)[i]
    id_error = idloss(data.input...)[1]
    push!(domain_dm, log(dm_error))
    push!(domain_id, log(id_error))
  end
  init = [outs..., rand(length(▸(dmloss, is(θp))))...]
  optimize(dmloss, ▸(dmloss, is(θp)), ◂(dmloss, i), init;
            callbacks=[savedomain])
  #Plots.plot([domain_dm, domain_id], title="Domain loss optimization")

  # id_loss optimization
  id_dm = []
  id_id = []
  function saveid(data)
    dm_error = dmloss(data.input...)[i]
    id_error = idloss(data.input...)[1]
    push!(id_dm, log(dm_error))
    push!(id_id, log(id_error))
  end
  init = [outs..., rand(length(▸(idloss, is(θp))))...]
  optimize(idloss, ▸(idloss, is(θp)), ◂(idloss, 1), init;
            callbacks=[saveid])
  #Plots.plot([id_dm, id_id], title="Id loss optimization")

  # naive_loss optimization
  naive_id = []
  function savenaive(data)
    id_error = naiveloss(data.input...)[j]
    push!(naive_id, log(id_error))
  end
  init = [rand(length(inputs))...]
  optimize(naiveloss, ▸(naiveloss), ◂(naiveloss, is(ϵ), 1), init;
            callbacks=[savenaive])
  #Plots.plot(naive_id, title="Naive loss optimization")
  domain_dm, domain_id, id_dm, id_id, naive_id
end
