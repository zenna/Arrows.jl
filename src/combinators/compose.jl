# Helpers 1#
pfx(prefix::Symbol, name::Symbol) = Symbol(:prefix_, name)
pfx(prefix::Symbol, arr::Arrow) = pfx(prefix, name(arr))

## Unary Combinators ##
"Wrap an `arr` in a container `CompArrow` `wrap(f) = g`, where `g(x) = f(x)"
function wrap(arr::Arrow, name=Symbol(:wrap_, name(arr)))::CompArrow
  carr = CompArrow(name)
  sarr = add_sub_arr!(carr, arr)
  link_to_parent!(sarr, loose)
  carr
end

## ComposeL: Combinators for composition of one or more arrows ##
"Compose the names of `arr1` and `arr2`"
composename(arr1::Arrow, arr2::Arrow) = Symbol(name(arr2), :_to_, name(arr1))

"PortMap which aligns out_ports of `g` to in_ports of `f`"
composeall(f::Arrow, g::Arrow)::PortMap = PortMap(zip(out_ports(g), in_ports(f)))

"""
Compose `g` with `f` `to the right` (f ∘ g)
# Arguments:
- `f`:
- `g`:
- `name`: Name of result, defaults to `name(g)_to_name(f)`
- `portmap`: d
# Returns:
- (f ∘ g):
  Any  loose `in_ports(f)` will become in_ports of res, after `in_ports(g)`
  Any loose `out_ports(g)` will become out_ports of res, after `out_ports(f)`
"""
function compose(f::Arrow,
                 g::Arrow,
                 portmap::PortMap=composeall(f, g),
                 name=composename(f, g))
  carr = CompArrow(name)
  fsarr = add_sub_arr!(carr, f)
  gsarr = add_sub_arr!(carr, g)
  for (gport, fport) in portmap
    gsport = sub_port(gsarr, gport)
    fsport = sub_port(fsarr, fport)
    link_ports!(gsport, fsport)
  end
  link_to_parent!(gsarr, is_in_port ∧ loose)
  link_to_parent!(fsarr, is_out_port ∧ loose)
  link_to_parent!(fsarr, is_in_port ∧ loose)
  link_to_parent!(gsarr, is_out_port ∧ loose)
  carr
end

"Compose `g` with `f` `to the right` (f ∘ g)"
∘(f::Arrow, g::Arrow) = compose(f, g)

"Right compose: f >> g. (f ∘ g)"
>>(f, g) = compose(g, f)

"Right compose: g >> f. (g ∘ f)"
<<(f, g) = compose(f, g)

"""Compose with shared inputs by name"""
function compose_share_by_name(f::Arrow,
  g::Arrow,
  portmap::PortMap=composeall(f, g),
  arr_name=composename(f, g))
carr = CompArrow(arr_name)
fsarr = add_sub_arr!(carr, f)
gsarr = add_sub_arr!(carr, g)
for (gport, fport) in portmap
  gsport = sub_port(gsarr, gport)
  fsport = sub_port(fsarr, fport)
  gsport ⥅ fsport
end
ports = Dict{Name, SubPort}()
for gport in ▹(gsarr)
  newport = link_to_parent!(gport)
  ports[name(newport)] = sub_port(newport)
end
for fport in ▹(fsarr)
  if loose(fport)
    nm = fport |> deref |> name
    if nm ∈ keys(ports)
      ports[nm] ⥅ fport
    else
      link_to_parent!(fport)
    end
  end
end

link_to_parent!(fsarr, is_out_port ∧ loose)
link_to_parent!(gsarr, is_out_port ∧ loose)
carr
end

"""Create a stack of arrows, inputs in order"""
function stack(arrs::Vararg{<:Arrow})::CompArrow
  carr = CompArrow(:stack)
  for arr in arrs
    sarr = add_sub_arr!(carr, arr)
    link_to_parent!(sarr, is_in_port ∧ loose)
    link_to_parent!(sarr, is_out_port ∧ loose)
  end
  carr
end

"""dupl first Project Inputs to Output
# Arguments
- `arr: x_1 × ⋯ × x_n -> y_1 ⋯ × y_n`
# Returns
- `res: x_1 × ⋯ × x_n -> x_1 × ⋯ × x_n × y_1 ⋯ × y_n
"""
function dupl_first(arr::Arrow, pass=in_ports(arr), name=pfx(:dupl_first, arr))
  carr = CompArrow(:dupl_first)
  sarr = add_sub_arr!(carr, arr)
  link_to_parent!(sarr, is_in_port ∧ loose)
  link_to_parent!(sarr, is_out_port ∧ loose)
  for port in pass
    is_in_port(port) || throw(DomainError())
    lsport = src(sub_port(sarr, port))
    pprops = Props(props(lsport); is_in_port = false)
    rsport = add_port!(carr, pprops)
    link_ports!(lsport, rsport)
  end
  carr
end

"Replace link `src -> dst` with link `src -> a`, `b -> dst`"
function replace_link!(src::SubPort, dst::SubPort, a::SubPort, b::SubPort)
  unlink_ports!(src, dst)
  link_ports!(src, a)
  link_ports!(b, dst)
  nothing
end

"Places `sarr` before orig: ∀ src -> dst ∈ orig"
function inner_compose!(orig::SubArrow, sarr::SubArrow)
  dsts = ▹(orig)
  srcs = src.(dsts)
  as = ▹(sarr)
  bs = ◃(sarr)
  same(map(length, [srcs, dsts, as, bs])) || throw(ArgumentError("Wrong number of ports"))
  foreach(replace_link!, srcs, dsts, as, bs)
  bs
end

inner_compose!(orig::SubArrow, arr::Arrow) =
  inner_compose!(orig, add_sub_arr!(parent(orig), arr))

"Add `arr` to `parent(sprts)` and link sprts[i] to arr[▹i]"
function compose!(sprts::Vector{SubPort}, arr::Arrow)::Vector{SubPort}
  length(sprts) == n▸(arr)
  carr = anyparent(sprts...)
  sarr = add_sub_arr!(carr, arr)
  foreach(link_ports!, sprts, ▹(sarr))
  ◃(sarr)
end
