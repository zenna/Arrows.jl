"Inverse Gather"
function inv_gather()
  c = CompArrow(:inv_gather, [:z, :y, :w, :θgather], [:x,])
  z, y, w, θ = ▸(c)
  x, = ◂(c)
  scatter = add_sub_arr!(c, ScatterNdArrow())
  add = add_sub_arr!(c, AddArrow())
  addprop!(θp, θ)
  z ⥅ (scatter, 1)
  y ⥅ (scatter, 2)
  w ⥅ (scatter, 3)
  (scatter, 1) ⥅ (add, 1)
  θ ⥅ (add, 2)
  (add, 1) ⥅ x
  c
end
