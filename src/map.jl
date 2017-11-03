# map(f::Function, sprt::SubPort) = map(lift(f), sprt)

function map(f::Function, sprt::SubPort, val)
  src = SourceArrow(val)
  sarr = add_sub_arr!(parent(sprt), src)
  map(f, sprt, ◃(sarr, 1))
end

function map(f::Function, val, sprt::SubPort)
  src = SourceArrow(val)
  sarr = add_sub_arr!(parent(sprt), src)
  map(f, ◃(sarr, 1), sprt)
end

map(f::Function, sprts::SubPort...) = map(lift(f), sprts...)

"Mapping `arr` just applies arr when arr is parametric"
function map(arr::Arrow, sprts::SubPort...)
  length(▸(arr)) == length(sprts) || throw(ArgumentError("wrong #sprts"))
  carr = anyparent(sprts...)
  sarr = add_sub_arr!(carr, arr)
  foreach(sprts, ▹(sarr)) do l, r
    l ⥅ r
  end
  ◃(sarr, 1)
end
