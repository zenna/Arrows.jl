# TODO: move the primitive pgfs into a separate file

function pgf(arr::MulArrow)
  # TODO: make it general
  carr = CompArrow(Symbol(:pgf_, :mul), [:x, :y], [:z, :th])
  x, y, z, th = sub_ports(carr)
  x * y ⥅ z
  y ⥅ th
  carr
end

function pgf(arr::AddArrow)
  # TODO: make it general
  carr = CompArrow(Symbol(:pgf_, :add), [:x, :y], [:z, :th])
  x, y, z, th = sub_ports(carr)
  x + y ⥅ z
  y ⥅ th
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

carr = CompArrow(:test, [:x, :y], [:z])
x, y, z = sub_ports(carr)
(x * y + x) ⥅ z
carr

inv_carr = invert(carr)
carr(1, 2)

pgf_carr = pgf(carr)
pgf_carr(1, 2)

inv_carr(3, 2, 1)
