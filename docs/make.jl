using Documenter
using Arrows

import Arrows: PortProps, AbstractArrow

makedocs(
  modules = [Arrows],
  authors = "Zenna Tavares and contributers",
  format = :html,
  sitename = "Arrows.jl",
  pages = [
    "Home"=>"index.md",
    "Internals"=>
      ["Types"=>"types.md",
       "CompArrow API"=>"comparrow.md",
      ]
  ]
)


deploydocs(
  repo = "github.com/zenna/Arrows.jl.git",
  julia="0.6",
  deps=nothing,
  make=nothing,
  target="build",
)
