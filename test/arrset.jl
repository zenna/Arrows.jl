workspace()
using Arrows
using Arrows.Library
q = (clone(2) >>> addarr |> mularr) >>> sinarr
expose(q)
