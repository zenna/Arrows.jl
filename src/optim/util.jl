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
function verify_loss(arr::CompArrow, inputs=nothing)
    ϵtol = 1e-10
    domain_loss, i = domain_ovrl(arr)
    pgfarr = pgf(arr)
    if inputs == nothing
        n_inputs = length(▸(pgfarr))
        inputs = rand(n_inputs)
    end
    outs = pgfarr(inputs...)
    loss_values = domain_loss(outs...)
    isapprox(loss_values[i], 0, atol=ϵtol) || throw(ArgumentError("Domain loss with pgf values should be 0, is $loss_values instead."))

    invarr = invert(arr)
    idloss = id_loss(arr, invarr)
    loss_values = idloss(outs...)
    isapprox(loss_values[1], 0, atol=ϵtol) || throw(ArgumentError("Id loss with pgf values should be 0, is $loss_values instead."))
end

"Runs optimization on the specified domain/id loss and (for now) prints the results."
function verify_optim(arr::CompArrow, inputs=nothing, opt="domain")
    # the given arrow shouldn't have parametric ports.
    if inputs == nothing
        inputs = rand(length(▸(arr, !is(θp))))
    end
    @assert length(inputs) == length(▸(arr, !is(θp)))
    outs = arr(inputs...)
    invarr = invert(arr)
    aprx_totalize!(invarr)
    optimizer, index = domain_ovrl(arr)
    if opt == "id"
        optimizer = id_loss(arr, invarr)
        index = 1
    end
    init = [outs..., rand(length(▸(optimizer, is(θp))))...]
    error, argmin = optimize(optimizer, ▸(optimizer, is(θp)), ◂(optimizer, index), init)
    println("The optimized $opt loss is $error.")

    opt_inputs = invarr(outs..., argmin...)
    opt_outs = arr(opt_inputs...)
    println("The actual outputs are $outs.")
    println("The optimized outputs are $opt_outs.")
end
