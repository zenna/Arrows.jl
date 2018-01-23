"Compose a parameter selecting `UnknownArrow` into `arr`"
function psl(arr::Arrow)
  θ▸, normal▸ = partition(is(θp), ▸(arr))
  farr = UnknownArrow(Symbol(:psl_, name(arr)),
                             [nm.name for nm in name.(normal▸)],
                             [nm.name for nm in name.(θ▸)])

  carr = CompArrow(Symbol(:ri_, name(arr)))
  sarr = add_sub_arr!(carr, arr)
  pslsarr = add_sub_arr!(carr, farr)  # parameter selecting function

  # Link every outport to parent
  foreach(link_to_parent!, ◃(sarr))

  # Link every normal input to
  foreach(link_to_parent!, ▹(sarr, !is(θp)))

  normalsrc = map(src, ▹(sarr, !is(θp)))
  @assert length(normalsrc) == length(▹(pslsarr))

  # Link every input to the parameter selecting function
  foreach(⥅, normalsrc, ▹(pslsarr))
  @assert length(◃(pslsarr)) == length(▹(sarr, is(θp)))
  foreach(⥅, ◃(pslsarr), ▹(sarr, is(θp)))
  @assert is_valid(carr)
  carr
end

"f:x->y, invf:y [× θ] -> x => x -> x"
function supervised(fwd::Arrow, inv::Arrow)
  carr = CompArrow(Symbol(:xx_, name(fwd)))
  fwdsarr = add_sub_arr!(carr, fwd)
  invsarr = add_sub_arr!(carr, inv)
  foreach(link_to_parent!, ▹(fwdsarr))
  length(◃(fwdsarr)) == length(▹(invsarr, !is(θp))) || throw(ArgumentError("mismatch nports"))
  foreach(⥅, ◃(fwdsarr), ▹(invsarr, !is(θp)))
  foreach(link_to_parent!, ▹(invsarr, is(θp)))
  foreach(link_to_parent!, ◃(invsarr))
  @assert is_valid(carr)
  carr
end

"Make this shit work"
function supervisedloss(xxarr::Arrow)
  carr = CompArrow(Symbol(:sup_loss, name(xxarr)))
  xxsarr = add_sub_arr!(carr, xxarr)
  foreach(link_to_parent!, ▹(xxsarr)) # add all inputs
  normalsrc = map(src, ▹(xxsarr, !is(θp)))
  @assert length(normalsrc) == length(◃(xxsarr, !is(ϵ)))
  total = sumδ(normalsrc, ◃(xxsarr, !is(ϵ)))
  loss = add_port_like!(carr, deref(total))
  total ⥅ loss
  addprop!(supϵ, loss)
  link_to_parent!(xxsarr, is_out_port ∧ loose)
  @assert is_valid(carr)
  carr
end

function test_foreign_arr(arr = TestArrows.xy_plus_x_arr())
  invarr = aprx_invert(arr)
  pslarr = psl(invarr)
  pslarr = invarr
  superarr = supervised(arr, pslarr)
  suploss = supervisedloss(superarr)
  # optimize(suploss, over? ◂(suploss, is(ϵ)), init?)
end
