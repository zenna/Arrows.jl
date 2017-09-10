"arrow which computes sum of `n` inputs"
function addn_accum(n::Integer)
  inp_names = [Symbol(:ϕ_, i) for i=1:n]
  carr = CompArrow(:addn, inp_names, [:sum])
  angles = in_sub_ports(carr)
  curr_angle = first(angles)
  sum_angles = [curr_angle]
  for i = 2:n
    addarr = add_sub_arr!(carr, AddArrow())
    link_ports!(curr_angle, (addarr, 1))
    link_ports!(angles[i], (addarr, 2))
    curr_angle = out_sub_port(addarr, 1)
    push!(sum_angles, curr_angle)
  end
  link_ports!(curr_angle, (carr, 1))
  carr, sum_angles
end

function addn(n::Integer)::CompArrow
  addn_accum(n)[1]
end

"Clips its inpot to interval [A, B]"
struct ClipArrow{A, B} <: PrimArrow end
name(::ClipArrow)::Symbol = :clip
port_props(::ClipArrow) = unary_arith_port_props()

"clip(x; a, b) ="
clip(x, a=-1, b=1) = max(a, min(b, x))
