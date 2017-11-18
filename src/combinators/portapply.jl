
function portapply!(arr::Arrow, sprts::SubPort...)
  parent = anyparent(sprts...)
  length(sprts) == length(▸(arr)) || throw(ArgumentError("mismatch #prts with arr"))
  sprts = map(src, sprts)
  @assert all(should_src, sprts)
  sarr = add_sub_arr!(parent, arr)
  foreach(⥅, sprts, ▹(sarr))
  if length(◃(sarr)) == 1
    ◃(sarr, 1)
  else
    ◃(sarr)
  end
end

(arr::CompArrow)(sprts::SubPort...) = portapply!(arr, sprts...)

for Arrtype in subtypes(PrimArrow)
  (arr::Arrtype)(sprts::SubPort...) = portapply!(arr, sprts...)
end
