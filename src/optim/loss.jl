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

mean_errors!(ϵsprts::Vector{SubPort}) = mean(ϵsprts)
mean_errors!(arr::CompArrow) = mean_errors!(arr[isϵ])

"δ(fwd(inv(y)), y)"
function iden_loss!(fwd::Arrow, inv::Arrow)::Arrow
  #FIXME iden_loss is a bad name
  #FIXME why is this so complicated? 
  carr = CompArrow(:iden_loss)
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

iden_loss(fwd::Arrow, inv::Arrow) = iden_loss!(deepcopy(fwd), deepcopy(inv))
