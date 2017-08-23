PortMap = Dict{Port, Any}

interpret(::DivArrow, x, y) = (x / y,)
interpret(::MulArrow, x, y) = (x * y,)
interpret(::SubArrow, x, y) = (x - y,)
interpret(::AddArrow, x, y) = (x + y,)
interpret(::EqualArrow, x, y) = (x == y,)
interpret(::CondArrow, i, t, e) = ((i ? t : e),)
interpret(arr::SourceArrow) = (arr.value,)
interpret(::IdentityArrow, x) = (x,)

function interpret(arr::CondArrow, port_map::PortMap)
  i, t, e = in_ports(arr)
  port_map[i] ? port_map[t] : port_map[e]
end

get_inputs(arr::Arrow, port_map::PortMap) =
  [port_map[inp] for inp in in_ports(arr)]

"unpack inputs of `arr` from `port_map` and interpret"
unpack_interpret(arr::Arrow, port_map::PortMap) = interpret(arr, get_inputs(arr, port_map)...)
unpack_interpret(arr::CompArrow, port_map::PortMap) = interpret(arr, get_inputs(arr, port_map)...)
unpack_interpret(arr::CondArrow, port_map::PortMap) = interpret(arr, port_map)

"Can we compute the out_ports of `arr` based on values in `port_map`?"
can_compute(arr::Arrow, port_map) =
  all((inp in keys(port_map) for inp in in_ports(arr)))

function can_compute(arr::CondArrow, port_map)
  i, t, e = in_ports(arr)
  if i in keys(port_map)
    (port_map[i] && t in keys(port_map)) || (!port_map[i] && e in keys(port_map))
  else
    false
  end
end

"Update portmap s.t. port_map[out_port[i]] = ys[i]"
function merge_port_map!(subarr::Arrow, ys, port_map)
  length(ys) == num_out_ports(subarr) || throw(DomainError())
  print_port_map(port_map)
  merge!(port_map, Dict(zip(out_ports(subarr), ys)))
  print_port_map(port_map)
end

"Propagate values in `port_map` from src to dest port"
function propagate_port_map!(port::Port, arr::CompArrow, port_map)
  for neigh_port in out_neighbors(port, arr)
    port_map[neigh_port] = port_map[port]
  end
end

"is `port` required to compute the `port.arrow`?"
in_port_required{A<:Arrow}(port::Port{A}, port_map) = true

function in_port_required(port::Port{CondArrow}, port_map)::Bool
  arr = port.arrow
  i, t, e = in_ports(arr)

  if port == i
    true
  elseif i in keys(port_map)
    @assert (port in [t, e])
    return (port_map[i] && (port == t)) || (!port_map[i] && (port == e))
  else
    false
  end
end

"Do we need to compute the out_ports of `arr` based on values in `port_map`?"
function need_compute(subarr::Arrow, arr::CompArrow, port_map)
  for port in out_neighbors(subarr, arr)
    if (port.arrow == arr) || (need_compute(port.arrow, arr, port_map) &&
                               in_port_required(port, port_map))
      return true
    end
  end
  false
end

function print_port_map(port_map)
  for (k, v) in port_map
    println(k, "=>", v)
  end
  println("--")
end

"Evaluate arr(xs...) by interpretation"
function interpret(arr::CompArrow, xs...)
  length(xs) == num_in_ports(arr) || throw(DomainError())
  port_map = Dict{Port, Any}(zip(in_ports(arr), xs))
  out_ports_done(port_map) = all((op in keys(port_map) for op in out_ports(arr)))
  for port in in_ports(arr)
    propagate_port_map!(port, arr, port_map)
  end

  # Naive impl that repeatedly checks for each subarrow can we
  # (i) compute its output (i.e., are all inputs ready)
  # (ii) do we need to (maybe unnecessary due to control flow)
  i = 0
  while !out_ports_done(port_map)
    i = i + 1
    # @assert i < 4
    println("Length port_map", length(port_map))
    for sa in sub_arrows(arr)
      print_port_map(port_map)
      if can_compute(sa, port_map) && need_compute(sa, arr, port_map)
        ys = unpack_interpret(sa, port_map)
        merge_port_map!(sa, ys, port_map)
        print_port_map(port_map)
        for port in out_ports(sa)
          propagate_port_map!(port, arr, port_map)
        end
      end
    end
  end
  [port_map[op] for op in out_ports(arr)]
end
