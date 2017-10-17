# FIXME. This is a mess

"""
Convert a function call to a composite arrow
# Arguments:
  `f`: Vararg::SubPort ->
"""
function unlinkcall(f, name::ArrowName, sprts::SubPort...)::Tuple{SubPort}
  all(is_dst.(sprts)) || throw(DomainError())
  parent_carr = anyparent(sprts...)
  src_sprts = src.(sprts...)
  # 1. Make new CompArrow whose in_ports are like sprts
  # Port Properties like sprts but all in_ports
  pprops = map(sprt -> Props(props(sprt); is_in_port=true), src_sprts)
  carr = CompArrow(name, [pprops...])
  # 2. Break all the kinks
  f_outs = s(f(▹(carr)...))
  # foreach(link_to_parent!, s(f(in_sub_ports(carr)...)))
  # 3. add carr to the parent, link sprts to in_ports of carr and return outports
  sarr = add_sub_arr!(parent_carr, carr)
  foreach(sprts, ▹(sarr)) do parent_sprt, inner_sprt, f_outs
    unlink_ports!(src(parent_sprt), parent_sprt)
    src(parent_sprt) ⥅ inner_sprt
    fouts ⥅ parent_sprt
  end
  tuple(◃(sarr)...)
end

unlinkcall(f, sprts::SubPort...) = unlinkcall(f, typeof(f).name.name, (sprts...))
unlinkcall(f, xs...) = f(xs...)

"Wrap untupled elements in a tuple"
tuple_untupled(x) = (x,)
tuple_untupled(xs::Vector) = tuple(xs...)
tuple_untupled(xs::Tuple) = xs

"Apply `f` to ▹ of carr"
applycarr(f, carr::CompArrow) = tuple_untupled(f(▹(carr)...))

"""
Convert a function call to a composite arrow
# Arguments:
- `f`: Vararg::SubPort -> Tuple{Vararg}::SubPort
- `name`: name of `CompArrow` to create
- `sprts`: `SubPort`s to apply `f` to
# Returns:
- `CompArrow` which computes `f(sprts...)`

```julia
f(x) = sin((x * x + x) / x)
carr = CompArrow(:test, [:x], [:y])
x = in_sub_port(carr, 1)
f(f(f(f(x))))
```

With `compcall`"
```julia
carr = CompArrow(:test, [:x], [:y])
x = in_sub_port(carr, 1)
compcall(f, (compcall(f, compcall(f, x))))
num_sub_arrows(carr)
```
"""
function compcall(f, name::ArrowName, sprts::SubPort...)::Tuple{SubPort}
  # Port Properties like sprts but all in_ports
  pprops = map(sprt -> Props(props(sprt); is_in_port=true), sprts)
  carr = CompArrow(name, [pprops...]) # 2. Apply f to these inports to construct internals of `carr`
  foreach(link_to_parent!, applycarr(f, carr))
  sarr = add_sub_arr!(anyparent(sprts...), carr)  # 3. add carr to the parent, link sprts to in_ports of carr and return outports
  foreach(⥅, sprts, ▹(sarr))
  tuple(◃(sarr)...)
end

compcall(f, sprts::SubPort...) = compcall(f, typeof(f).name.name, (sprts...))
compcall(f, xs...) = f(xs...)
