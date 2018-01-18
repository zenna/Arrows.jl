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

#FIXME: rename rm functions appropriately and move outside of invert
"Remove all `SubArrow`s in `carr` which have *any* unconnected port"
function rm_partially_loose_sub_arrows!(carr::CompArrow)
  # iterate until none left
  nremoved = 1
  while nremoved != 0
    nremoved = 0
    for sarr in sub_arrows(carr)
      nloose = length(filter(loose, sub_ports(sarr)))
      if nloose > 0
        # println("removing: ", sarr)
        rem_sub_arr!(sarr)
        nremoved = nremoved + 1
      end
    end
    # println("removed $nremoved !")
  end
  carr
end

function remove_dead_arrow(arr::Arrow, sarr::SubArrow)::Bool
  if all(loose, get_out_sub_ports(sarr))
    println("Removing $sarr")
    rem_sub_arr!(sarr)
    return true
  elseif any(loose, get_in_sub_ports(sarr))
    @assert false
  else
    return false
  end
end

function remove_dead_arrow(arr::DuplArrow{N}, sarr::SubArrow)::Bool where N
  # Make new dupl with excluding loose outports
  notlooseprtids = find(!loose, get_sub_ports(sarr))
  if loose(get_in_sub_ports(sarr, 1))
    @assert false "unhandled"
  elseif length(notlooseprtids) - 1 != N
    newdupl = DuplArrow(length(notlooseprtids) - 1)
    # println("Replacing Dupl $sarr with $newdupl")
    # And wire up new dupl to those that remain
    pidmap = PortIdMap(zip(notlooseprtids, 1:length(get_ports(newdupl))))
    replace_sub_arr!(sarr, newdupl, pidmap)
    return true
  else
    return false
  end
end

"Remove sarr from `carr` if any ports of sarr are unconnected"
function remove_dead_arrows!(carr)
  changemade = true
  while changemade
    for sarr in sub_arrows(carr)
      # @show sarr
      changemade &= remove_dead_arrow(deref(sarr), sarr)
      badloose = (loose ∧ should_dst ∧ is(θp)).(inner_sub_ports(carr))
    end
  end
  carr
end

function link_param_ports!(carr::CompArrow)
  link_to_parent!(carr, loose ∧ should_dst ∧ is(θp))
  carr
end

"Invert `arr`, approximately totalize, and check the `domain_error`"
function aprx_invert(arr::CompArrow,
                     inner_inv::Function=inv,
                     sprtabvals::Dict{SubPort, AbValues} = Dict{SubPort, AbValues}())
  aprx_totalize!(domain_error!(invert(arr, inner_inv, sprtabvals)))
end

function invreplace(carr::CompArrow, sarr::SubArrow, tparent::TraceParent, abtvals::TraceAbValues; inv=inv)
  pmap = id_portid_map(carr)
  f = inv_rename! ∘ remove_dead_arrows! ∘ link_param_ports! ∘ fix_links! ∘ invert_all_ports!
  f(carr), pmap
end

function invreplace(parr::PrimArrow, sarr::SubArrow, tparent::TraceParent, abtvals::TraceAbValues; inv=inv)
  idabvals = tarr_idabv(TraceSubArrow(tparent, sarr), abtvals)
  inv(parr, sarr, idabvals)
end

"copy and `invert!` `arr`"
function invert(arr::CompArrow,
                inner_inv=inv,
                sprtabvals::SprtAbValues = SprtAbValues())
  arr = duplify(arr)
  sprtabvals = SprtAbValues(⬨(arr, sprt.port_id) => abvals for (sprt, abvals) in sprtabvals)
  abvals = traceprop!(arr, sprtabvals)
  custinvreplace = (arr, sarr, tparent, abtvals) -> invreplace(arr, sarr, tparent, abtvals; inv=inner_inv)
  tracewalk(custinvreplace, arr, abvals)[1]
end

"copy and `invert!` `arr`"
invert(arr::CompArrow, inner_inv, nmabv::NmAbValues) =
  invert(arr, inner_inv, sprtabv(arr, nmabv))

"Cannot invert arrow"
struct InvertError <: Exception
  arr::Arrow
  abv::XAbValues
end

Base.showerror(io::IO, e::InvertError) =
  print(io, "Cannot invert: $(e.arr) with values $(e.abv)")
