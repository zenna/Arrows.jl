function fwd_kinematics(θ1, θ2, θ3)
    x = sin(θ1) + sin(θ1 + θ2) + sin(θ1 + θ2 + θ3)
    y = cos(θ1) + cos(θ1 + θ2) + cos(θ1 + θ2 + θ3)
    x, y
end

function arr(f)
    nms = code_lowered(f)[1].slotnames[2:end]
    nms = Symbol[nms...]
    c = CompArrow
    inames = nms[1:3]
    onames = nms[4:5]
    carr = CompArrow(:fwd_kinematics, inames, onames)
    insprts = ▹(carr)
    outs = f(insprts...)
    foreach(⥅, outs, ◃(carr))
    carr
end

# BenchmarkArrows.drawscene([1.0, 1.0, 1.0], 1.0, 1.0)

# function fwd_kinematics_arr()
#   fwd_kinematics_arr = CompArrow(:fwd_kin, [:θ1, :θ2, :θ3], [:x, :y]);
#   θ1, θ2, θ3, x, y = sub_ports(fwd_kinematics_arr);
#   xx, yy = fwd_kinematics(θ1, θ2, θ3);
#   link_ports!(xx, x);
#   link_ports!(yy, y);
#   fwd_kinematics_arr
# end

function optiminv(input, fwdarr)
  invarr = invert(fwdarr);
  total = Arrows.aprx_totalize(invarr);
  id = id_loss(fwdarr, total)
  init = vcat(input, rand(length(▸(id, is(θp)))))
  res = optimize(id, ▸(id, is(θp)), ◂(id, is(ϵ), 1), init)
  res
  @show res
  res.argmin, total
end

function randinverse(inv_kinematics, input, fwdarr)
    res, total = optiminv(input, fwdarr)
    output = total(input..., res...)
end
