# FIXME. This is a mess


singleton_detuple(x) = length(x) == 1 ? x[1] : x
singleton_detuple(x) = length(x) == 1 ? x[1] : x
s(sprt::SubPort)::Tuple{SubPort}  = (sprt,)
s(sprts::Tuple{SubPort}) = sprts

"""Stick in `mid` between lefet ports and rigt ports"""
function stick_in_between!(lefts::Vector{SubArrow},
                           mids::Vector{SubPort},
                           rights::Vector{SubArrow})
  pcarr = anyparent(lefts..., mids..., rights...)
  foreach(lefts, mids, rights) do lefts, mids, rights
    unlink_ports!(left, right)
    left ⥅ mid_in
    mid_out ⥅ right
  end
end

stick_in_between!(left::SubArrow, mid::Arrow, right::SubArrow) =
  stick_in_between!()

"""Convert a function call to a composite arrow
# Arguments
f: Vararg::SubPort ->
"""
function unlinkcall(f, name::ArrowName, sprts::SubPort...)::Tuple{SubPort}
  all(is_dst.(sprts)) || throw(DomainError())
  parent_carr = anyparent(sprts...)
  src_sprts = src.(sprts...)
  # 1. Make new CompArrow whose in_ports are like sprts
  # Port Properties like sprts but all in_ports
  pprops = map(sprt -> PortProps(port_props(sprt); is_in_port=true), src_sprts)
  carr = CompArrow(name, [pprops...])
  # 2. Break all the kinks
  f_outs = s(f(in_sub_ports(carr)...))
  # foreach(link_to_parent!, s(f(in_sub_ports(carr)...)))
  # 3. add carr to the parent, link sprts to in_ports of carr and return outports
  sarr = add_sub_arr!(parent_carr, carr)
  foreach(sprts, in_sub_ports(sarr)) do parent_sprt, inner_sprt, f_outs
    unlink_ports!(src(parent_sprt), parent_sprt)
    src(parent_sprt) ⥅ inner_sprt
    fouts ⥅ parent_sprt
  end
  tuple(out_sub_ports(sarr)...)
end

unlinkcall(f, sprts::SubPort...) = unlinkcall(f, typeof(f).name.name, (sprts...))
unlinkcall(f, xs...) = f(xs...)

"""Convert a function call to a composite arrow
# Arguments
f: Vararg::SubPort ->

  `f(x) = sin((x * x + x) / x)
  carr = CompArrow(:test, [:x], [:y])
  x = in_sub_port(carr, 1)
  f(f(f(f(x))))
  num_sub_arrows(carr)
    16

  # Try instead with CompCall
  carr = CompArrow(:test, [:x], [:y])
  x = in_sub_port(carr, 1)
  compcall(f, (compcall(f, compcall(f, x))))
  num_sub_arrows(carr)
  `

"""
function compcall(f, name::ArrowName, sprts::SubPort...)::Tuple{SubPort}
  # 1. Make new CompArrow whose in_ports are like sprts
  parent_carr = anyparent(sprts...)
  # Port Properties like sprts but all in_ports
  pprops = map(sprt -> PortProps(port_props(sprt); is_in_port=true), sprts)
  carr = CompArrow(name, [pprops...])
  # 2. Apply f to these inports to construct internals of `carr`
  foreach(link_to_parent!, s(f(in_sub_ports(carr)...)))
  # 3. add carr to the parent, link sprts to in_ports of carr and return outports
  sarr = add_sub_arr!(parent_carr, carr)
  foreach(sprts, in_sub_ports(sarr)) do parent_sprt, inner_sprt
    parent_sprt ⥅ inner_sprt
  end
  tuple(out_sub_ports(sarr)...)
end

compcall(f, sprts::SubPort...) = compcall(f, typeof(f).name.name, (sprts...))
compcall(f, xs...) = f(xs...)
