"f(x, y) = (x - y)^2 sqrt"
function diff_arrow()
  carr = SubtractArrow() >> SqrArrow() >> SqrtArrow()
  rename!(carr, :diff)
  set_error_port!(◂(carr, 1))
  carr
end

"Arrow which computes distance a distance between two elements of type `T`"
δ(T::DataType) = diff_arrow()
δ!(a::SubPort, b::SubPort) = sqrt(sqr(a - b))

"accumulate errors"
function meanerror(invarr::CompArrow)
  thebest = CompArrow(:thebest)
  sarr = add_sub_arr!(thebest, invarr)
  ϵprts = ◂(invarr, is(ϵ))
  meanarr = add_sub_arr!(thebest, MeanArrow(length(ϵprts)))
  i = 1
  foreach(Arrows.link_to_parent!, ▹(sarr))
  for sprt in ◃(sarr)
    if is(ϵ)(deref(sprt))
      sprt ⥅ ▹(meanarr, i)
      i += 1
    else
      Arrows.link_to_parent!(sprt)
    end
  end
  Arrows.link_to_parent!(◃(meanarr, 1))
  # FIXME This sint idϵ its the mean of potentially different errors
  # I would want the most specific type
  addprop!(idϵ, deref((Arrows.dst(◃(meanarr, 1)))))
  @assert is_valid(thebest)
  thebest
end

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
"""
function id_loss!(fwd::Arrow, inv::Arrow)::Arrow
  #FIXME why is this so complicated?
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
