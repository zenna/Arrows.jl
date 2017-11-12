"Is `sprt` (function of) output of `SourceArrow`, i.e. constant"
is_src_source(sprt::SubPort) = isa(deref(src(sprt)).arrow, SourceArrow)

# Hack until constant propagation is done
function inv(sarr::SubArrow, tparent::TraceParent, abtvals::AbTraceValues)
  carr = deref(sarr)
  # FIXME: Remove const_in, now that we have abtvals
  const_in = map(is_src_source, ▹(sarr))
  inv(deref(sarr), sarr, const_in, tparent, abtvals)
end
# FIXME? is it ok to use invert!, what about source

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
  @assert needswitch1 == needswitch2 "$needswitch1 $needswitch2"
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

function remove_dead_arrows!(carr)
  foreach(sub_arrows(carr)) do sarr
    nloose = length(filter(loose, sub_ports(sarr)))
    if nloose == length(sub_ports(sarr))
      rem_sub_arr!(sarr)
    else
      @assert nloose == 0 "All or none ports should be zero, but is $nloose"
    end
  end
  carr
end

link_param_ports!(carr::CompArrow) = link_to_parent!(carr, loose ∧ should_dst)

"Invert `arr`, approximately totalize, and check the `domain_error`"
function aprx_invert(arr::CompArrow,
                     inner_inv=inv,
                     sprtabvals::Dict{SubPort, AbValues} = Dict{SubPort, AbValues}())
  aprx_totalize!(domain_error!(invert(arr, inner_inv, sprtabvals)))
end

function invreplace(carr::CompArrow, sarr::SubArrow, tparent::TraceParent, abtvals::AbTraceValues; inv=inv)
  pmap = id_portid_map(carr)
  f = inv_rename! ∘ remove_dead_arrows! ∘ link_param_ports! ∘ fix_links! ∘ invert_all_ports!
  f(carr), pmap
end

function invreplace(parr::PrimArrow, sarr::SubArrow, tparent::TraceParent, abtvals::AbTraceValues; inv=inv)
  const_in = map(is_src_source, ▹(sarr))
  inv(parr, sarr, const_in, tparent, abtvals)
end

"copy and `invert!` `arr`"
function invert(arr::CompArrow,
                inner_inv=inv,
                sprtabvals::Dict{SubPort, AbValues} = Dict{SubPort, AbValues}())
  arr = duplify(arr)
  sprtabvals = Dict{SubPort, AbValues}(⬨(arr, sprt.port_id) => abvals for (sprt, abvals) in sprtabvals)
  abvals = traceprop!(arr, sprtabvals)
  custinvreplace = (arr, sarr, tparent, abtvals) -> invreplace(arr, sarr, tparent, abtvals; inv=inner_inv)
  newtracewalk(custinvreplace, arr, abvals)[1]
end
