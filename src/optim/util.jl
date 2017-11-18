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
function plot_optim(arr::CompArrow, n_trials::Integer, newinv=inv, newpgf=pgf)
  inputs=rand(length(▸(arr, !is(θp))))
  outs = arr(inputs...)
  dmloss, i = domain_ovrl(arr, newinv)
  invarr = invert(arr, newinv)
  aprx_totalize!(invarr)
  idloss = id_loss(arr, invarr)
  naiveloss, j = naive_loss(arr, outs)
  pgfarr = pgf(arr, newpgf)
  all_loss = []
  min_dd = []; min_di = []; min_id = []; min_ii = []; min_ni = []
  iter_domain = 0; iter_id = 0; iter_naive = 0
  norm_init = []; pgf_init = []
  norm_error = []; pgf_error = []

  for trials = 1:n_trials
    println("Doing trial number $trials...")
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
    push!(min_dd, domain_dm[length(domain_dm)])
    push!(min_di, domain_id[length(domain_dm)])
    iter_domain = max(iter_domain, length(domain_dm))
    #Plots.plot([domain_dm, domain_id], title="Domain loss optimization")
    println("Optimized wrt domain_loss...")
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
    push!(min_id, id_dm[length(id_dm)])
    push!(min_ii, id_id[length(id_id)])
    push!(norm_init, id_id[1])
    push!(norm_error, id_id[length(id_id)])
    iter_id = max(iter_id, length(id_dm))

    inp_init = rand(length(▸(arr, !is(θp))))
    pgf_vals = pgfarr(inp_init...)
    pgfinit = [outs..., pgf_vals[length(outs)+1:length(pgf_vals)]...]
    init_loss = idloss(pgfinit...)[1]
    error, _ = optimize(idloss, ▸(idloss, is(θp)), ◂(idloss, 1), pgfinit)
    push!(pgf_init, init_loss)
    push!(pgf_error, error)
    #Plots.plot([id_dm, id_id], title="Id loss optimization")
    println("Optimized wrt id_loss...")
    # naive_loss optimization
    naive_id = []
    function savenaive(data)
      id_error = naiveloss(data.input...)[j]
      push!(naive_id, log(id_error))
    end
    init = [rand(length(inputs))...]
    optimize(naiveloss, ▸(naiveloss), ◂(naiveloss, is(ϵ), 1), init;
              callbacks=[savenaive])
    push!(min_ni, naive_id[length(naive_id)])
    iter_naive = max(iter_naive, length(naive_id))
    #Plots.plot(naive_id, title="Naive loss optimization")
    println("Optimized wrt naive_loss...")
    push!(all_loss, (domain_dm, domain_id, id_dm, id_id, naive_id))
  end

  println("Getting the means...")
  # get the means at each iteration for each loss
  mean_dd = zeros(iter_domain); mean_di = zeros(iter_domain)
  for i = 1:iter_domain
    n_dd = 0; n_di = 0
    for j = 1:length(all_loss)
      dd = all_loss[j][1]
      di = all_loss[j][2]
      if length(dd) >= i
        mean_dd[i] = (mean_dd[i]*n_dd+dd[i])/(n_dd+1)
        n_dd += 1
      end
      if length(di) >= i
        mean_di[i] = (mean_di[i]*n_di+di[i])/(n_di+1)
        n_di += 1
      end
    end
  end

  mean_id = zeros(iter_id); mean_ii = zeros(iter_id)
  for i = 1:iter_id
    n_id = 0; n_ii = 0
    for j = 1:length(all_loss)
      id = all_loss[j][3]
      ii = all_loss[j][4]
      if length(id) >= i
        mean_id[i] = (mean_id[i]*n_id+id[i])/(n_id+1)
        n_id += 1
      end
      if length(ii) >= i
        mean_ii[i] = (mean_ii[i]*n_ii+ii[i])/(n_ii+1)
        n_ii += 1
      end
    end
  end

  mean_ni = zeros(iter_naive)
  for i = 1:iter_naive
    n_ni = 0
    for j = 1:length(all_loss)
      ni = all_loss[j][5]
      if length(ni) >= i
        mean_ni[i] = (mean_ni[i]*n_ni+ni[i])/(n_ni+1)
        n_ni += 1
      end
    end
  end
  pgf_norm = (norm_init, pgf_init, norm_error, pgf_error)
  mean_losses = (mean_dd, mean_di, mean_id, mean_ii, mean_ni)
  min_losses = (min_dd, min_di, min_id, min_ii, min_ni)
  mean_losses, min_losses, pgf_norm
end
