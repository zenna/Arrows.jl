"Is `sprt` (function of) output of `SourceArrow`, i.e. constant"
is_src_source(sprt::SubPort) = isa(deref(src(sprt)).arrow, SourceArrow)

"Inversion of "
function inv(arr::CompArrow, const_in)
  @assert !any(const_in)
  (invert(arr), id_portid_map(arr))
end

# Hack until constant propagation is done
function inv(sarr::SubArrow)
  carr = deref(sarr)
  const_in = map(is_src_source, ▹(sarr))
  for sprt in ▹(sarr)
    arr = deref(src(sprt)).arrow
    if isa(arr, SourceArrow)
      @show arr.value
    end
  end
  inv(deref(sarr), const_in)
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

"""
Construct a parametric inverse of `arr`
# Arguments:
- `arr`: Arrow to invert
- `dispatch`: Dict mapping arrow class to invert function
# Returns:
- A parametric inverse of `arr`
"""
function invert!(arr::CompArrow)::CompArrow
  check_reuse(arr)
  link_loose_dsts(carr) = link_to_parent!(carr, loose ∧ should_dst)
  outer = inv_rename! ∘ link_loose_dsts ∘ fix_links! ∘ invert_all_ports!
  walk!(inv, outer, arr)
end

invert(arr::CompArrow) = invert!(duplify!(deepcopy(arr)))
aprx_invert(arr::CompArrow) = aprx_totalize!(domain_error!(invert(arr)))
