## Types for different kinds of Arrows
## ==================================

"A functional unit which transforms `I` inputs to `O` outputs"
abstract Arrow{I, O}

## Port
## ====
# Smaller precision might suffice
typealias ArrowId Int
typealias PinId Int

"Get the inport of an arrow with pinid `n` if it exists"
nthinport{I,O}(::Arrow{I,O}, n::PinId) =
  (@assert n <= I "fail: n($n) <= I($I)"; InPort(1, n))

"Get the outport of an arrow with pinid `n` if it exists"
nthoutport{I,O}(::Arrow{I,O}, n::PinId) =
  (@assert n <= O "fail: n($n) <= O($O)"; OutPort(1, n))

"""An entry or exit to an Arrow, analogous to argument position of multivariate function.

  A port is uniquely determined by the arrow it belongs to and a pin.
  By convention, a port which is on the parent arrow will have `arrowid = 1`.
  `pinid`s are contingous from `1:I` or `1:O` for inputs and outputs respectively.

  On the boundary of a composite arrow, ports are simultaneously inports (since they take
  input from outside world) and outputs (since inside they project outward to
  subarrows)."""
abstract Port

"A Port which *accepts* input from the output of other arrows (i.e. `OutPort`s)"
immutable InPort <: Port
  arrowid::ArrowId
  pinid::PinId
end

"A Port which *projects* output to the inputs of other arrows (i.e. `InPort`s)"
immutable OutPort <: Port
  arrowid::ArrowId
  pinid::PinId
end

"Is this port on the boundary?"
isboundary(p::Port) = p.arrowid == 1

## Generic Arrow
## ==============
inports{I,O}(a::Arrow{I, O}) = InPort[InPort(1, i) for i = 1:I]
outports{I,O}(a::Arrow{I, O}) = OutPort[OutPort(1, i) for i = 1:O]

ninports{I,O}(a::Arrow{I,O}) = I
noutports{I,O}(a::Arrow{I,O}) = O
nports{I,O}(a::Arrow{I,O}) = I + O

## Type Stuff
## ==========

function replacetyp(a::Arrow, d::DimType)
  error("unimplemented")
end

"Return constraints for all variables within arrow"
function alldimconstraints(a::Arrow)
  error("unimplemented")
end


include("arrowtypes/primarrow.jl")
include("arrowtypes/compositearrow.jl")
include("arrowtypes/namedarrow.jl")
include("arrowtypes/arrowset.jl")
