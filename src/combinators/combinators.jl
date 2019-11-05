# Arrow combinators: compose Arrows into composite arrows #
module Combinators
import InteractiveUtils

using Spec

using ..ArrowMod: CompArrow, SubArrow, ArrowRef, AbstractPort, SubPort, Arrow, Port, PrimArrow, PortMap

include("compose.jl")
include("portapply.jl")

end