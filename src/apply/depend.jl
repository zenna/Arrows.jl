"Assigns `true` or `false` to traceports which are input_1 of `CondArrow`s"
CondMap = Dict{SubPort, Bool}

"`Value`s in `arr` needed to compute outputs of `subarr`"
function needed_values(::RealArrow, subarr::SubArrow, cond_map::CondMap)::Values
  Set(RepValue.(in_sub_ports(subarr)))
end

"`Value`s in `arr` needed to compute outputs of `subarr`"
function needed_values(::CondArrow, subarr::SubArrow, cond_map::CondMap)::Values
  i, t, e = in_sub_ports(subarr)
  if i in cond_map
    if cond_map[i]
      Set(RepValue(t))
    else
      Set(RepValue(e))
    end
  else
    Set()
  end
end

"`Value's do we need to compute `target`"
function needed_values(target::Value, cond_map::CondMap)::Values
  subarr = src_arrow(target)
  needed_values(deref(subarr), subarr, cond_map)
end

"`Value`s do we (unambiguously) need in order to determine `targets` inclusive"
function needed_values(targets::Values, cond_map::CondMap = CondMap())::Values
  all_needed = copy(targets)
  to_see = copy(targets)
  seen = Set{RepValue}()
  while !isempty(to_see)
    curr = pop!(to_see)
    push!(seen, curr)
    sub_needed = needed_values(curr, cond_map)
    union!(all_needed, sub_needed)
    union!(to_see, (n for n in sub_needed if n ∉ seen))
  end
  all_needed
end

function computable_values(::CondArrow, known::Values, subarr::SubArrow)::Values
  @assert false "not implemented"
end

function computable_values(::RealArrow, known::Values, subarr::SubArrow)::Values
  needed_values = in_values(subarr)
  # println("ARR is", deref(subarr))
  # println("Neede for ARR is ", needed_values)
  # println("but known is ", known)
  # println("in?", [(val, val ∈ known) for val in needed_values])
  # println("UNION ", union(known, needed_values))
  # @assert same((parent(value) for value in (known ∪ needed_values)))
  # for v1 in known
  #   for v2 in needed_values
  #     print("v1 - known", v1)
  #     println("v2 - needed", v2)
  #     println("equal?", v1 == v2)
  #   end
  # end

  if all((val ∈ known for val in needed_values))
    out_values(subarr)
  else
    Set{RepValue}()
  end
end

computable_values(known::Values, subarr::SubArrow) =
  computable_values(deref(subarr), known, subarr)

"`Value`s we can compute, given we know `known`, may interect with `known`"
function computable_values(known::Values, cond_map::CondMap = CondMap())::Values
  if isempty(known)
    Set()
  else
    val = first(known)
    arr = parent(val)
    union((computable_values(known, subarr) for subarr in sub_arrows(arr))...)
  end
end

"`Value`s we both can compute and need to determine `targets`"
function can_need_values(known::Values, targets::Values, cond_map::CondMap)::Values
  @assert same((parent(value) for value in (known ∪ targets)))
  # println("Target ", targets)
  # println("Needed ", needed_values(targets, cond_map))
  # println("Known ", known)
  # println("Computable ", computable_values(known, cond_map))
  intersect(setdiff(needed_values(targets, cond_map), known),
            computable_values(known, cond_map))
end
