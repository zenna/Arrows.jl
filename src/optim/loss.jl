"f(x, y) = (x - y)^2 sqrt"
function δarr()
  carr = CompArrow(:δ, [:x1, :x2], [:diff])
  x1, x2, diff = ⬨(carr)
  sqrt(sqr(x1 - x2)) ⥅ diff
  @assert is_wired_ok(carr)
  carr
end

"Arrow which computes distance a distance between two elements of type `T`"
δ!(a::SubPort, b::SubPort) = sqrt(sqr(a - b))

"∑δ(a,b)"
function sumδ(as::Vector{SubPort}, bs::Vector{SubPort})
  diffs = []
  foreach(as, bs) do sprt1, sprt2
    diff = δ!(sprt1, sprt2)
    push!(diffs, diff)
  end

  total = first(diffs)
  for i = 2:length(diffs)
    total += diffs[i]
  end
  total
end

"""
δ(f(f⁻¹(y)), y)
# Arguments
- `fwd`: f : x -> y
- `inv`; f⁻¹ : y (× θ) -> x
# Returns
- `id_loss`: y (× θ) -> loss::Real where loss = δ(f(f⁻¹(y)), y)
"""
function id_loss!(fwd::Arrow, inv::Arrow)::Arrow
  carr = CompArrow(:id_loss) #FIXME, loses name of fwd/inv
  invsarr = add_sub_arr!(carr, inv)
  fwdsarr = add_sub_arr!(carr, fwd)

  osports = ◃(invsarr)
  error_port = is(ϵ) ∘ deref
  for (i, sprt) in enumerate(filter(!error_port, osports))
    sprt ⥅ (fwdsarr, i)
  end

  for sprt in filter(error_port, osports)
    prt = add_port_like!(carr, deref(sprt))
    sprt ⥅ prt
  end

  # Diffs between inputs to inv and outputs of fwd
  foreach(link_to_parent!, ▹(invsarr))
  invinsprts = src.(▹(invsarr, !is(θp)))
  fwdoutsprts = ◃(fwdsarr, !is(ϵ))
  length(invinsprts) == length(fwdoutsprts) || throw(DomainError())
  total = sumδ(invinsprts, fwdoutsprts)
  loss = add_port_like!(carr, deref(total))
  total ⥅ loss
  addprop!(idϵ, loss)
  carr
end

id_loss(fwd::Arrow, inv::Arrow) = id_loss!(deepcopy(fwd), deepcopy(inv))


"From `f:y -> x`, `f: y -> error::Error oflosstype`"
function floss(arr::Arrow, lossf::Function, custϵ::Type{Err}=ϵ)
  carr = CompArrow(Symbol(:lx_, name(arr)))
  sarr = add_sub_arr!(carr, arr)
  foreach(link_to_parent!, ▹(sarr))
  foreach(link_to_parent!, ◃(sarr, is(ϵ)))
  xs = map(src, ▹(sarr, !is(θp)))
  total = lossf(xs, ◃(sarr, !is(ϵ)))
  loss = add_port_like!(carr, deref(total))
  total ⥅ loss
  addprop!(custϵ, loss)
  @assert is_wired_ok(carr)
  carr
end

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


# FIXME: FWD loss and Naive Loss are the same thing
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

"x -> y => x × y -> real"
function fwd_loss(arr::Arrow)
  carr = CompArrow(:fwd_loss)
  sarr = add_sub_arr!(carr, arr)
  foreach(link_to_parent!, ▹(sarr))
  y▸ = [add_port!(carr, setprop(In(), props(sprt))) for sprt in ◃(sarr)]
  y▹ = sub_port.(y▸)
  y◃ = ◃(sarr)
  total = sumδ(y◃, y▹)
  loss = add_port_like!(carr, deref(total))
  total ⥅ loss
  addprop!(idϵ, loss)
  carr
end

plus(x::SubPort) = x
plus(xs::SubPort...) = +(xs...)

"All losses"
function superloss(fwd::Arrow)
  invarr = aprx_invert(fwd)
  carr = CompArrow(Symbol(:net_loss, name(fwd)))
  finv = add_sub_arr!(carr, invarr)
  foreach(link_to_parent!, ▹(finv))
  finv◃ = ◃(finv, !is(ϵ))
  finv▹ = ▹(finv, !is(θp))
  fwd◃ = fwd(finv◃...)
  # There MUST be a better way
  if fwd◃ isa SubPort
    fwd◃ = [fwd◃]
  end

  # root mean square error, per port
  # δ◃s = [mean(δarr()(fwd◃[i], finv▹[i])) for i = 1:length(fwd◃)]
  # @assert false
  δ◃s = [δ!(fwd◃[i], finv▹[i]) for i = 1:length(fwd◃)]
  foreach(add!(idϵ) ∘ link_to_parent!, δ◃s)

  # sum rms over ports
  δidtot◃ = plus(δ◃s...)
  idtotal = link_to_parent!(δidtot◃)
  add!(idϵ)(idtotal)

  # Domain errors
  alldomϵ = ◃(finv, is(domϵ))
  sprt = plus(alldomϵ...)
  totdomϵ = link_to_parent!(sprt)
  add!(domϵ)(totdomϵ)

  # Both!
  both = sprt + δidtot◃
  bothe = link_to_parent!(both)

  foreach(link_to_parent!, ◃(finv))
  @assert is_wired_ok(carr)
  Dict(:idtotal => idtotal,
       :totdomϵ => totdomϵ,
       :invcarr => carr,
       :both => bothe)
end
