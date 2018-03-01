## to_dot(TestArrows.triple_add(), "triple_add.gv")
## dot -Tpdf triple_add.gv -o triple_add.pdf && open triple_add.pdf
using NamedTuples

"""create a simple `dot` file named `filename`
from a given `CompArrow."""
function to_dot(carr::CompArrow, filename)
  open(filename, "w") do f
    write(f, carr |> to_dot)
  end
end

"creates a dot file from the `CompArrow`"
function to_dot(carr::CompArrow)
  seen = Set{Symbol}()
  to_process = Set{CompArrow}([carr])
  id = 0
  dot = ""
  while !isempty(to_process)
    next = pop!(to_process)
    push!(seen, next |> name)
    answer = to_dot_inner(next, id)
    dot *= answer.dot
    id = answer.id
    union!(to_process, filter(answer.to_process) do c
                        name(c) ∉ seen
    end)
  end
  "digraph {\n" * dot * "}\n"
end

function to_dot_inner(carr::CompArrow, base_id)
  to_process = Set{CompArrow}()
  append(c::CompArrow) = push!(to_process, c)
  append(c) = c
  dot = ""
  sarrs = sub_arrows(carr)
  for (id, sarr) in enumerate(sarrs)
    dot *= "\tsubgraph cluster_$(base_id + id) {\n"
    dot *= to_dot(sarr)
    dot *= "\t}\n"
    append(sarr |> deref)
  end
  for (left, right) ∈ Arrows.links(carr)
    dot *= "$(name(left)) -> $(name(right));\n"
  end
  dot = "subgraph cluster_$base_id{\n" * dot_subgraph_name(carr) * dot * "}\n"
  @NT(id = base_id + length(sarrs) + 1,
      dot = replace(dot, "##", "xx"),
      to_process = to_process)
end

function dot_subgraph_name(arr)
  "\tlabel = \"Subgraph " * dot_name(arr) * "\";\n"
end
function dot_name(arr)::String
  moniker = name(arr)
  "$moniker"
end

function dot_name(sarr::SubArrow)::String
  arr = sarr |> deref
  moniker_arr = arr |> name
  dot_name(arr) * "($moniker_arr)"
end

as_dot_node(sarr::SubArrow) = as_dot_node(sarr, sarr |> deref)
function as_dot_node(sarr::SubArrow, carr::CompArrow)
  "\"$(name(carr))\""
end

function as_dot_node(sarr::SubArrow, arr::PrimArrow)
  moniker = sarr |> name
  moniker_arr = arr |> name
  "\"$moniker($moniker_arr)\""
end

dot_attributes(moniker, sarr::SubArrow) = dot_attributes(moniker, sarr, sarr |> deref)
function dot_attributes(moniker, sarr::SubArrow, ::CompArrow)
  "$moniker [fillcolor=\"#beaed4\", shape=box, style=filled];\n"
end

function dot_attributes(moniker, sarr::SubArrow, ::PrimArrow)
  #"$moniker [fillcolor=\"#fdc086\", shape=diamond, style=filled];\n"
  "$moniker [fillcolor=yellow, shape=diamond, style=filled];\n"
end

"""For a given `SubArrow`, list all of its `SubPorts`
and connect all the `▹` to the computation and it to
the  `◃`."""
function to_dot(sarr::SubArrow)
  moniker = as_dot_node(sarr)
  dot = dot_subgraph_name(sarr)
  dot *= dot_attributes(moniker, sarr)
  dot *= "\t" * string(["$n; " for n in 
            name.(⬨(sarr))]...,
          "\n")
  for sport in ▹(sarr)
    dot *= "\t$(name(sport)) -> $moniker;\n"
  end
  for sport in ◃(sarr)
    dot *= "\t$moniker -> $(name(sport));\n"
  end
  dot
end



function test_solve_triple_add()
  carr = TestArrows.triple_add()
  inv_carr = carr |> Arrows.invert
  wired, wirer = Arrows.solve_scalar(inv_carr)
  wired
end