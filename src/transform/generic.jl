"Generic Graph Transforations"

"Generic Graph Transformation"
function graph_transform(lambdas)
end

function pgf(x::AddArrow)::Arrow
  ...
end

"Transform `arr` into parameter generating function"
function pgf(arr::CompArrow)
  arr -> pgf(arr)
  graph_transform()
