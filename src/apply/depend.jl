"Assigns `true` or `false` to traceports which are input_1 of `CondArrow`s"
CondMap = Dict{TracePort, Bool}

"Which values in `arr` are needed to compute outputs of `subarr`"
function needed_values(arr::CompArrow, subarr::Arrow, cond_map::CondMap)
  in_ports(arr, subarr)
end

"Which `Value`s in `arr` are needed to compute outputs of `subarr`"
function needed_ports(arr::CompArrow, subarr::Arrow, cond_map::CondMap)
  i, t, e = in_ports(arr, sub_arrows)
  if i in cond_map
    if cond_map[i]
      t
    else
      e
    end
  else
    Set()
  end
end

"Which `Value's do we need to compute `target`"
function needed_ports(arr::CompArrow, target::Value, cond_map::CondMap)::Values
  subarr = src_arrow(target)
  needed_ports(arr, subarr, cond_map)
end

"Which values do we (unambiguously) need to determine `targets`?"
function needed_ports(arr::CompArrow, targets::Values,
                      cond_map::CondMap = CondMap())::Values
  all_needed = Set{Value}()
  to_see = copy(targets)
  seen = Set{Value}()
  while !isempty(to_see)
    curr = pop!(to_see)
    push!(seen, curr)
    sub_needed = needed_ports(arr, curr, cond_map)
    merge!(all_needed, sub_needed)
    merge!(to_see, (n for n in needed if n ∉ seen))
  end
  all_needed
end

"Which port_classes in `arr` can we compute, given we know `known`"
computable_ports(arr::Arrow, known::Values) =
  all((inp in keys(port_map) for inp in in_ports(arr)))

"Port classes in `arr` we both can and need to determine `targets`"
function can_need_ports(arr::CompArrow, known::Values, targets::Values,
                        cond_map::CondMap)
  needed_ports(arr, targets) ∪ computable_ports(arr, known)
end
