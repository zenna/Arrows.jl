# TODO: move θe primitive pgfs into a separate file

function pgf(arr::MulArrow)
  # TODO: make it general
  carr = CompArrow(Symbol(:pgf_, :mul), [:x, :y], [:z, :θ])
  x, y, z, θ = sub_ports(carr)
  addprop!(θp, θ)
  x * y ⥅ z
  y ⥅ θ
  carr
end

function pgf(arr::AddArrow)
  # TODO: make it general
  carr = CompArrow(Symbol(:pgf_, :add), [:x, :y], [:z, :θ])
  x, y, z, θ = sub_ports(carr)
  addprop!(θp, θ)
  x + y ⥅ z
  y ⥅ θ
  carr
end

function pgf(arr::SubtractArrow)
  # TODO: make it general
  carr = CompArrow(Symbol(:pgf_, :sub), [:x, :y], [:z, :θ])
  x, y, z, θ = sub_ports(carr)
  addprop!(θp, θ)
  x - y ⥅ z
  y ⥅ θ
  carr
end

function pgf(arr::SinArrow)
  # TODO: make it general
  carr = CompArrow(Symbol(:pgf_, :sin), [:x], [:y, :θ])
  x, y, θ = sub_ports(carr)
  addprop!(θp, θ)
  sinarr = add_sub_arr!(carr, SinArrow())
  link_ports!(x, (sinarr, 1))
  link_ports!((sinarr, 1), y)
  zero = add_sub_arr!(carr, SourceArrow(0))
  link_ports!((zero, 1), θ)
  carr
end

function pgf(arr::CosArrow)
  # TODO: make it general
  carr = CompArrow(Symbol(:pgf_, :cos), [:x], [:y, :θ])
  x, y, θ = sub_ports(carr)
  addprop!(θp, θ)
  cosarr = add_sub_arr!(carr, CosArrow())
  link_ports!(x, (cosarr, 1))
  link_ports!((cosarr, 1), y)
  zero = add_sub_arr!(carr, SourceArrow(0))
  link_ports!((zero, 1), θ)
  carr
end

function pgf(arr::SourceArrow)
  # TODO: make it general
  newarr = deepcopy(arr)
  rename!(newarr, Symbol(:pgf_, :source))
  newarr
end

function pgf(arr::IdentityArrow)
  # TODO: make it general
  newarr = deepcopy(arr)
  rename!(newarr, Symbol(:pgf_, :identity))
  newarr
end

function pgf(arr::LessThanArrow)
  # TODO: make it general
  carr = CompArrow(Symbol(:pgf_, :lessthan), [:x, :y], [:z, :θ1, :θ2])
  x, y, z, θ1, θ2 = sub_ports(carr)
  addprop!(θp, θ1)
  addprop!(θp, θ2)
  abs = add_sub_arr!(carr, AbsArrow())
  x < y ⥅ z
  x ⥅ θ1
  x - y ⥅ (abs, 1)
  link_ports!((abs, 2), θ2)
  carr
end

pgf_rename!(carr::CompArrow) = (rename!(carr, Symbol(:pgf_, carr.name)); carr)

pgf_in(sarr::SubArrow) = pgf(deref(sarr))
pgf_out = pgf_rename! ∘ (carr -> link_to_parent!(carr, loose ∧ should_src))

function pgf_change!(carr::CompArrow)
  for sarr in sub_arrows(carr)
    replarr, port_map = pgf_in(sarr), id_portid_map(deref(sarr))
    replace_sub_arr!(sarr, replarr, port_map)
  end
  pgf_out(carr)
end

pgf(carr::CompArrow) = pgf_change!(deepcopy(carr))
