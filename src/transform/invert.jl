
# x -> x, y -> y, z -> z
# FIXME: Switch to symbols instead of numbers
# TODO: Add is_valid for These portmaps to check
const BIN_PORT_MAP = Dict(1 => 3, 2 => 4, 3 => 1)
const SYMB_BIN_PORT_MAP = Dict(:x => :x, :y => :y, :z => :z)
inv{O}(arr::DuplArrow{O}) =
  (InvDuplArrow(O), merge(Dict(1 => O + 1), Dict(i => i - 1 for i = 2:O+1)))
inv(arr::AddArrow) = (inv_add(), BIN_PORT_MAP)
inv(arr::MulArrow) = (inv_mul(), BIN_PORT_MAP)
inv(arr::SourceArrow) = (SourceArrow(arr.value), Dict(1 => 1))
inv(arr::SubArrow) = inv(deref(arr))

function check_reuse(arr)
  if !no_reuse(arr)
    print("Must eliminate reuse of values before `invert`, use `duplify`")
    throw(DomainError())
  end
end

"Link `n` unlinked ports in arr{I, O} to yield `ret_arr{I, O + n}``"
function link_loose_ports{I}(arr::CompArrow{I})
  arr
  # is_loose_port(sub_port::SubPort) = should_src(subport) && !is_src(sub_port)
  # loose_ports = filter(is_loose_port, sub_ports(arr))
  # arr = CompArrow{I, O + length(loose_ports)}
end

inv{I, O}(arr::CompArrow{I, O}) = CompArrow{O, I}(Symbol(:inv_, name(arr)))

"Reorient an edge such that it goes from source to dst"
fix_link(link::Link)::Link = Link(switch(is_src, link...))

function fix_link!(link::Link)
  fixed = fix_link(link)
  if fixed != fix_link
    unlink_ports!(fixed...)
  end
end

"Make each in_port (resp, out_port) of `arr` an out_port (in_port)"
function invert_all_ports{I, O}(arr::CompArrow{I, O})::CompArrow
  CompArrow{O, I}(arr.name, arr, arr, arr)
  portmap = symb_iden_port_map(arr)
end

"`fix_link` all the links in `arr`"
function fix_links!(arr::CompArrow)::CompArrow
  foreach(fix_link!, links(arr))
  arr
end

"""Construct a parametric inverse of `arr`
Args:
  `arr`: Arrow to invert
  `dispatch`: Dict mapping arrow class to invert function
Returns:
  A (approximate) parametric inverse of `arrow`. The ith in_port of comp_arrow
  will be corresponding ith out_port error_ports and param_ports will follow"""
function invert(arr::CompArrow)::CompArrow
  check_reuse(arr)
  outer = link_loose_ports ∘ fix_links! ∘ invert_all_ports
  walk(inv, outer, arr)
end
