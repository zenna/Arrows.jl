function portapply!(arr::Arrow, sprts::SubPort...)
  parent = anyparent(sprts...)
  length(sprts) == length(▸(arr)) || throw(ArgumentError("mismatch #prts with arr"))
  sprts = map(src, sprts)
  @assert all(should_src, sprts)
  sarr = add_sub_arr!(parent, arr)
  foreach(⥅, sprts, ▹(sarr))
  ◃(sarr)
end

(arr::CompArrow)(sprts::SubPort...) = portapply!(arr, sprts...)

for Arrtype in filter(isleaftype, subtypes(PrimArrow))
  (arr::Arrtype)(sprts::SubPort) = portapply!(arr, sprts...)
end
