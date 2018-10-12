
"""
Apply an arrow like a function to subports as inputs

- add `arr` to parent of subports (should have same parent)
- link ports by name
- return out_sub_port(s) of `arr`

```jldoctest
julia> carr = TestArrows.xy_plus_x_arr()
xyx : x::Any × y::Any -> z::Any
2 sub arrows
is_valid? true

julia> SqrtArrow()(Dict(:x=>out_sub_ports(carr)[1]))
SubPort ##677_2 ◃y::Any on sqrt[2]
```
"""
function portapplykwarg!(arr::Arrow, nm_sprts::Dict{Symbol, SubPort})
  @pre same(map(parent, values(nm_sprts)))
  @pre length(nm_sprts) == length(▸(arr)) # : mismatch #prts with arr
  @pre all((nm ∈ port_sym_name.(▸(arr)) for nm in keys(nm_sprts))) # "Missing Port name"
  sprts = values(nm_sprts)
  parentarr = anyparent(sprts...)
  sprts = map(src, sprts)
  @assert all(should_src, sprts)
  sarr = add_sub_arr!(parentarr, arr)
  for (nm, sprt) in nm_sprts
    pid = ▸(deref(sarr), nm).port_id
    src(sprt) ⥅ ⬨(sarr, pid)
  end
  if length(◃(sarr)) == 1
    ◃(sarr, 1)
  else
    ◃(sarr)
  end
end


function portapply!(arr::Arrow, sprts::SubPort...)
  @pre same(map(parent, sprts))
  @pre length(sprts) == length(▸(arr)) # : mismatch #prts with arr
  @assert same(map(parent, sprts))
  parentarr = anyparent(sprts...)
  length(sprts) == length(▸(arr)) || throw(ArgumentError("mismatch #prts with arr"))
  sprts = map(src, sprts)
  @assert all(should_src, sprts)
  sarr = add_sub_arr!(parentarr, arr)
  foreach(⥅, sprts, ▹(sarr))
  if length(◃(sarr)) == 1
    ◃(sarr, 1)
  else
    ◃(sarr)
  end
end

(arr::CompArrow)(sprt::SubPort) = portapply!(arr, sprt)
(arr::CompArrow)(sprt::SubPort, sprts::SubPort...) = portapply!(arr, sprt, sprts...)
(arr::CompArrow)(nm_sprts::Dict{Symbol, SubPort}) = portapplykwarg!(arr, nm_sprts)

for Arrtype in InteractiveUtils.subtypes(PrimArrow)
  (arr::Arrtype)(sprt::SubPort) = portapply!(arr, sprt)
  (arr::Arrtype)(sprt::SubPort, sprts::SubPort...) = portapply!(arr, sprt, sprts...)
  (arr::Arrtype)(nm_sprts::Dict{Symbol, SubPort}) = portapplykwarg!(arr, nm_sprts)
end
