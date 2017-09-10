"Forward kinematics of 2D robot arm"
function fwd_2d_linkage(nlinks::Integer)
  inp_names = [Symbol(:ϕ_, i) for i=1:nlinks]
  carr = CompArrow(:fwd_kin, inp_names, [:x, :y])
  angles = in_sub_ports(carr)
  curr_angle = first(angles)
  sum_angles = [curr_angle]
  for i = 2:nlinks
    addarr = add_sub_arr!(carr, AddArrow())
    link_ports!(curr_angle, (addarr, 1))
    link_ports!(angles[i], (addarr, 2))
    curr_angle = out_sub_port(addarr, 1)
    push!(sum_angles, curr_angle)
  end

  total_sin = add_sub_arr!(carr, addn(length(sum_angles)))
  for (i, angle) in enumerate(sum_angles)
    sinarr = add_sub_arr!(carr, SinArrow())
    link_ports!(angle, (sinarr, 1))
    link_ports!((sinarr, 1), (total_sin, i))
  end

  total_cos = add_sub_arr!(carr, addn(length(sum_angles)))
  for (i, angle) in enumerate(sum_angles)
    cosarr = add_sub_arr!(carr, CosArrow())
    link_ports!(angle, (cosarr, 1))
    link_ports!((cosarr, 1), (total_cos, i))
  end

  x, y = out_sub_ports(carr)
  link_ports!((total_sin, 1), x)
  link_ports!((total_cos, 1), y)
  carr
end
