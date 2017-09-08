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
inv(arr::NegArrow) = (NegArrow(),  Dict(1 => 2, 2 => 1))
inv(arr::ExpArrow) = (LogArrow(),  Dict(1 => 2, 2 => 1))
inv(arr::IdentityArrow) = (IdentityArrow(),  Dict(1 => 2, 2 => 1))

# inv(arr::Gather) = (GatherNdArrow())

function check_reuse(arr)
  if !no_reuse(arr)
    print("Must eliminate reuse of values before `invert`, use `duplify`")
    throw(DomainError())
  end
end

"Do I need to switch this `link`"
function need_switch(l::Link)
  # TODO: Handle other cases
  println(l[1])
  println(l[2])

  println("src ", should_src(l[1]), " ", is_src(l[1]))
  println("src ", should_src(l[2]), " ", is_src(l[2]))

  println("dst ", should_dst(l[1]), " ", is_dst(l[1]))
  println("dst ", should_dst(l[2]), " ", is_dst(l[2]))

  needswitch1 = should_src(l[1]) ⊻ is_src(l[1])
  needswitch2 = should_dst(l[2]) ⊻ is_dst(l[2])
  @assert needswitch1 == needswitch2 "$needswitch1 $needswitch2"
  needswitch1
end

function fix_link!(link::Link)
  if need_switch(link)
    println("Switching")
    unlink_ports!(link...)
    link_ports!(link[2], link[1])
  else
    println("Not switching!")
  end
  nothing
end

"`fix_link` all the links in `arr`"
function fix_links!(arr::CompArrow)::CompArrow
  foreach(fix_link!, links(arr))
  arr
end

"Make each in_port (resp, out_port) of `arr` an out_port (in_port)"
function invert_all_ports!(arr::CompArrow)::CompArrow
  foreach(p -> is_in_port(p) ? make_out_port!(p) : set_in_port!(p), ports(arr))
  arr
end

inv_rename!(arr::CompArrow) = (rename!(arr, Symbol(:inv_, arr.name)); arr)

"""Construct a parametric inverse of `arr`
Args:
  `arr`: Arrow to invert
  `dispatch`: Dict mapping arrow class to invert function
Returns:
  A (approximate) parametric inverse of `arrow`. The ith in_port of arr
  will be corresponding ith out_port error_ports and param_ports will follow"""
function invert!(arr::CompArrow)::CompArrow
  check_reuse(arr)
  outer = inv_rename! ∘ link_loose_ports! ∘ fix_links! ∘ invert_all_ports!
  walk!(inv, outer, arr)
end
