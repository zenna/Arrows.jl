# Helpers 1#
pfx(prefix::Symbol, name::Symbol) = Symbol(:prefix_, name)
pfx(prefix::Symbol, arr::Arrow) = pfx(prefix, name(arr))

## Loose Port ##
"Receiving (dst) port has no incoming edges"
loose_dst(sport::SubPort)::Bool = should_dst(sport) && !is_dst(sport)

"Receiving (src) port has no outgoing edges"
loose_src(sport::SubPort)::Bool = should_src(sport) && !is_src(sport)

"Create a new port in `parent(sport)` and link `sport` to it"
function link_to_parent!(sport::SubPort)
  if on_boundary(sport)
    println("invalid on boundary ports")
    throw(DomainError())
  end
  arr = parent(sport)
  newport = add_port_like!(arr, deref(sport))
  if is_out_port(sport)
    link_ports!(sport, newport)
  else
    @assert is_in_port(sport)
    link_ports!(newport, sport)
  end
  newport
end

"Link `n` unlinked ports in arr{I, O} to yield `ret_arr{I, O + n}`"
function link_loose_ports!(arr::CompArrow)::CompArrow
  for sport in inner_sub_ports(arr)
    if loose_dst(sport)
      @assert is_parameter_port(deref(sport)) sport
      link_to_parent!(sport)
    end
  end
  arr
end

"Link `parent(sarr) -> sport` ∀ `sport` is loose in_port of sarr"
function link_loose_in_ports!(sarr::SubArrow)
  for sport in in_sub_ports(sarr)
    if loose_dst(sport)
      link_to_parent!(sport)
    end
  end
end

"Link `sport -> parent(sarr)` ∀ `sport` is loose in_port of sarr"
function link_loose_out_ports!(sarr::SubArrow)
  for sport in out_sub_ports(sarr)
    if loose_src(sport)
      link_to_parent!(sport)
    end
  end
end

## Compose ##

"Compose the names of `arr1` and `arr2`"
compname(arr1::Arrow, arr2::Arrow) = Symbol(name(arr2), :_to_, name(arr1))

"PortMap which aligns out_ports of `g` to in_ports of `f`"
composeall(f::Arrow, g::Arrow)::PortMap = PortMap(zip(out_ports(g), in_ports(f)))

"""Compose `g` with `f` `to the right` (f ∘ g)
# Arguments:
- `f`:
- `g`:
- `name`: Name of result, defaults to name(g)_to_name(f)
- `portmap`:
# Returns:
- (f ∘ g):
  Any  loose `in_ports(f)` will become in_ports of res, after `in_ports(g)`
  Any loose `out_ports(g)` will become out_ports of res, after `out_ports(f)`
"""
function compose(f::Arrow,
                 g::Arrow,
                 portmap::PortMap=composeall(f, g),
                 name=compname(f, g))
  # Make empty comparrow th
  carr = CompArrow(name)
  fsarr = add_sub_arr!(carr, f)
  gsarr = add_sub_arr!(carr, g)
  for (gport, fport) in portmap
    gsport = sub_port(gsarr, gport)
    fsport = sub_port(fsarr, fport)
    link_ports!(gsport, fsport)
  end
  link_loose_in_ports!(gsarr)
  link_loose_out_ports!(fsarr)
  link_loose_in_ports!(fsarr)
  link_loose_out_ports!(gsarr)
  carr
end

"Compose `g` with `f` `to the right` (f ∘ g)"
∘(f::Arrow, g::Arrow) = compose(f, g)

"Right compose: f >> g. (f ∘ g)"
>>(f, g) = compose(g, f)

"Right compose: g >> f. (g ∘ f)"
<<(f, g) = compose(f, g)

"""Create a stack of arrows, inputs in order"""
function stack(arrs::Vector{<:Arrow})::CompArrow
  carr = CompArrow(name)
  for arr in arrs
    sarr = add_sub_arr!(carr, arr)
    link_loose_in_ports!(sarr)
    link_loose_out_ports(sarr)
  end
  carr
end


"""dupl first Project Inputs to Output
# Arguments
- `arr: x_1 × ⋯ × x_n -> y_1 ⋯ × y_n`
# Returns
- `res: x_1 × ⋯ × x_n -> x_1 × ⋯ × x_n × y_1 ⋯ × y_n
"""
function top(arr::Arrow, name+)
  carr = CompArrow(name)
  sarr = add_sub_arr!!(carr, arr)
  link_loose_in_ports!(sarr)
  link_loose_out_ports!(sarr)
  for lsport in in_sub_port(carr)
    rsport = add_out_port_like!(sport)
    link_ports!(lsport, rsport)
  end
  carr
end
