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

"Remove `sarr` from `arr` if any inports or some outports loose"
function remove_dead_arrow!(arr::Arrow, sarr::SubArrow)::Bool
  if all(loose, get_out_sub_ports(sarr))
    println("Removing because all out_prts loose $sarr")
    rem_sub_arr!(sarr)
    return true
  elseif any(loose, get_in_sub_ports(sarr))
    println("Removing because some in_prts loose $sarr ")
    rem_sub_arr!(sarr)
    true
  else
    return false
  end
end

function remove_dead_arrow!(arr::DuplArrow{N}, sarr::SubArrow)::Bool where N
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
      changemade &= remove_dead_arrow!(deref(sarr), sarr)
      badloose = (loose ∧ should_dst ∧ is(θp)).(inner_sub_ports(carr))
    end
  end
  carr
end
