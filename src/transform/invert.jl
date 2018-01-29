"Is `sprt` (function of) output of `SourceArrow`, i.e. constant"
is_src_source(sprt::SubPort) = isa(deref(src(sprt)).arrow, SourceArrow)

"Check that no subports with more than out outgoing edge"
function check_reuse(arr)
  if !no_reuse(arr)
    throw(ArgumentError("Eliminate reuse before `invert`, use `duplify"))
  end
end

"Do I need to switch this `link`"
function need_switch(l::Link)
  needswitch1 = should_src(l[1]) ⊻ is_src(l[1])
  needswitch2 = should_dst(l[2]) ⊻ is_dst(l[2])
  @assert needswitch1 == needswitch2 "$needswitch1 $needswitch2 $l"
  needswitch1
end

"If a link is backwards, unlink reverse the direction"
function fix_link!(link::Link)
  if need_switch(link)
    unlink_ports!(link...)
    link_ports!(link[2], link[1])
  end
  nothing
end

"`fix_link` all the links in `arr`"
fix_links!(arr::CompArrow)::CompArrow = (foreach(fix_link!, links(arr)); arr)

"Make each in_port (resp, out_port) of `arr` an out_port (in_port)"
function invert_all_ports!(arr::CompArrow)::CompArrow
  foreach(p -> is_in_port(p) ? make_out_port!(p) : set_in_port!(p), ports(arr))
  arr
end

"Rename `arr` to `:inv_oldname`"
inv_rename!(arr::CompArrow) = (rename!(arr, Symbol(:inv_, arr.name)); arr)

function link_param_ports!(carr::CompArrow)
  link_to_parent!(carr, loose ∧ should_dst ∧ is(θp))
  carr
end

"Invert `arr`, approximately totalize, and check the `domain_error`"
function aprx_invert(arr::CompArrow,
                     inner_inv::Function=inv,
                     sprtabvals::Dict{SubPort, AbVals} = Dict{SubPort, AbVals}())
  aprx_totalize!(domain_error!(invert(arr, inner_inv, sprtabvals)))
end

function invreplace(carr::CompArrow, sarr::SubArrow, tparent::TraceParent, abtvals::TraceAbVals; inv=inv)
  pmap = id_portid_map(carr)
  f = inv_rename! ∘ remove_dead_arrows! ∘ link_param_ports! ∘ fix_links! ∘ invert_all_ports!
  f(carr), pmap
end

function invreplace(parr::PrimArrow, sarr::SubArrow, tparent::TraceParent, abtvals::TraceAbVals; inv=inv)
  idabvals = tarr_idabv(TraceSubArrow(tparent, sarr), abtvals)
  inv(parr, sarr, idabvals)
end

"copy and `invert!` `arr`"
function invert(arr::CompArrow,
                inner_inv=inv,
                sprtabvals::SprtAbVals = SprtAbVals())
  arr = duplify(arr)
  sprtabvals = SprtAbVals(⬨(arr, sprt.port_id) => abvals for (sprt, abvals) in sprtabvals)
  abvals = traceprop!(arr, sprtabvals)
  custinvreplace = (arr, sarr, tparent, abtvals) -> invreplace(arr, sarr, tparent, abtvals; inv=inner_inv)
  tracewalk(custinvreplace, arr, abvals)[1]
end

"copy and `invert!` `arr`"
invert(arr::CompArrow, inner_inv, nmabv::NmAbVals) =
  invert(arr, inner_inv, sprtabv(arr, nmabv))

"Cannot invert arrow"
struct InvertError <: Exception
  arr::Arrow
  abv::XAbVals
end

Base.showerror(io::IO, e::InvertError) =
  print(io, "Cannot invert: $(e.arr) with values $(e.abv)")
