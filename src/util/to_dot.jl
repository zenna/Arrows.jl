## to_dot(TestArrows.triple_add(), "triple_add.gv")
## dot -Tpdf triple_add.gv -o triple_add.pdf && open triple_add.pdf

"""create a simple `dot` file named `filename`
from a given `CompArrow."""
function to_dot(carr::CompArrow, filename)
  open(filename, "w") do f
    write(f, carr |> to_dot)
  end
end

"creates a dot file from the `CompArrow`"
function to_dot(carr::CompArrow)
  dot = ""
  for (id, sarr) in enumerate(sub_arrows(carr))
    dot *= "\tsubgraph cluster_$id {\n"
    dot *= to_dot(sarr)
    dot *= "\t}\n"
  end
  for (left, right) ∈ Arrows.links(carr)
    dot *= "$(name(left)) -> $(name(right));\n"
  end
  dot = "digraph {\n" * dot * "}"
  replace(dot, "#", "x")
end

"""For a given `SubArrow`, list all of its `SubPorts`
and connect all the `▹` to the computation and it to
the  `◃`."""
function to_dot(sarr::SubArrow)
  moniker = name(sarr)
  moniker_arr = sarr |> deref |> name
  dot = "\tlabel = \"Subgraph $moniker "
  dot *= "($moniker_arr)\";\n"
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



