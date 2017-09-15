"arrow which computes sum of `n` inputs"
function addn_accum(n::Integer)
  inp_names = [Symbol(:ϕ_, i) for i=1:n]
  carr = CompArrow(:addn, inp_names, [:sum])
  vals = in_sub_ports(carr)
  curr_val = first(vals)
  sum_vals = [curr_val]
  for i = 2:n
    addarr = add_sub_arr!(carr, AddArrow())
    link_ports!(curr_val, (addarr, 1))
    link_ports!(vals[i], (addarr, 2))
    curr_val = out_sub_port(addarr, 1)
    push!(sum_vals, curr_val)
  end
  link_ports!(curr_val, (carr, 1))
  carr, sum_vals
end

function addn_accum_linke(n::Integer)::CompArrow
  carr, sum_vals = addn_accum(n)
  for (i, asum) in enumerate(sum_vals)
    pprop = PortProps(false, Symbol(:midsum, i), Real, Set())
    prt = add_port!(carr, pprop)
    link_ports!(asum, prt)
  end
  @assert is_wired_ok(carr)
  carr
end

function addn(n::Integer)::CompArrow
  addn_accum(n)[1]
end

"Clips its `x` to interval `[a b]"
clip(x, l, u) = max(l, min(u, x))


# struct ClipArrow{A, B} <: PrimArrow end
# name(::ClipArrow)::Symbol = :clip
# port_props(::ClipArrow) = unary_arith_port_props()
#
# "clip(x; a, b) ="
# clip(x, a=-1, b=1) = max(a, min(b, x))
