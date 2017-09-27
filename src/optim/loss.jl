"f(x, y) = (x - y)^2 sqrt"
function diff_arrow()
  carr = SubtractArrow() >> SqrArrow() >> SqrtArrow()
  rename!(carr, :diff)
  set_error_port!(out_port(carr, 1))
  carr
end

"Arrow which computes distance a distance between two elements of type `T`"
δ(T::DataType) = diff_arrow()
δ!(a::SubPort, b::SubPort) = sqrt(sqr(a - b))

"accumulate errors"
function meanerror(invarr::CompArrow)
  thebest = CompArrow(:thebest)
  sarr = add_sub_arr!(thebest, invarr)
  ϵprts = filter(is(ϵ), ◂(invarr))
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

"""
Appends Identity loss

δ(f(f⁻¹(y)), y)

# Arguments


Algorithm
For each outport of inv find *corresponding* inport to fwd
Do that composition
foreach  inport to inv find corresponding outport of fwd
foreach of those pairs compute diff

TODO
How to do corresponding?

How to modify graph

how to distinguish id loss from id whatever
- I need more fine grained labels
- labels should be over laping
-
"""
function id_loss!(fwd::Arrow, inv::Arrow)::Arrow
  #FIXME why is this so complicated?
  carr = CompArrow(:id_loss) #FIXME, loses name of fwd/inv
  invsarr = add_sub_arr!(carr, inv)
  fwdsarr = add_sub_arr!(carr, fwd)

  # TODO: Make ports correspond
  # How to do correspondance? We dont want to match error outports
  # Can we assume number is the same
  # Can't we do it more semantically
  # We need a richer notion of an error port
  osports = out_sub_ports(invsarr)
  error_port = is(ϵ) ∘ deref
  for (i, sprt) in enumerate(filter(!error_port, osports))
    sprt ⥅ (fwdsarr, i)
  end

  for sprt in filter(error_port, osports)
    prt = add_port_like!(carr, deref(sprt))
    sprt ⥅ prt
  end

  diffs = []
  for (i, sprt) in enumerate(in_sub_ports(invsarr))
    prt = add_port_like!(carr, deref(sprt))
    prt ⥅ sprt
    if !(is(θp)(prt))
      diff = δ!(sub_port(carr, prt.port_id), out_sub_port(fwdsarr, i))
      push!(diffs, diff)
    end
  end

  total = first(diffs)
  for i = 2:length(diffs)
    total += diffs[i]
  end

  loss = add_port_like!(carr, deref(total))
  total ⥅ loss
  carr
end

id_loss(fwd::Arrow, inv::Arrow) = id_loss!(deepcopy(fwd), deepcopy(inv))
