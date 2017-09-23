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
  ϵprts = filter(is_error_port, ◂s(invarr))
  meanarr = add_sub_arr!(thebest, MeanArrow(length(ϵprts)))
  i = 1
  foreach(Arrows.link_to_parent!, ▹s(sarr))
  for sprt in ◃s(sarr)
    if is_error_port(sprt)
      sprt ⥅ ▹(meanarr, i)
      i += 1
    else
      Arrows.link_to_parent!(sprt)
    end
  end
  Arrows.link_to_parent!(◃(meanarr, 1))
  ϵ!(Arrows.dst(◃(meanarr, 1)))
  @assert is_wired_ok(thebest)
  thebest
end

"Identity Loss : δ(f(f⁻¹(y)), y)"
function id_loss!(fwd::Arrow, inv::Arrow)::Arrow
  #FIXME id_loss is a bad name
  #FIXME why is this so complicated?
  carr = CompArrow(:id_loss)
  invsarr = add_sub_arr!(carr, inv)
  fwdsarr = add_sub_arr!(carr, fwd)
  for (i, sprt) in enumerate(out_sub_ports(invsarr))
    sprt ⥅ (fwdsarr, i)
  end

  diffs = []
  for (i, sprt) in enumerate(in_sub_ports(invsarr))
    prt = add_port_like!(carr, deref(sprt))
    prt ⥅ sprt
    if !is_parameter_port(prt)
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
