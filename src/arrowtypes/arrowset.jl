## ArrowSet
## =======

import Base: .>>, >>, >>>, |>
export firstarrset, expose

"""An ArrowSet represents a set of possible Arrows.

  It is formalised as a function from a vector of real values to an arrow.
  This formalism is constructive, in the sense we can
"""
immutable ArrowSet{I,O} <: Arrow{I,O}
  isparam::BitArray{1}   # ith elem = is ith inport a parameter inport
  arrow::CompositeArrow
  function ArrowSet(isparam::BitArray{1}, arrow::CompositeArrow)
    @assert length(isparam) == ninports(arrow)
    new{I, O}(isparam, arrow)
  end
end

# Printing
string{I,O}(x::ArrowSet{I,O}) = "ArrowSet{$I,$O}"
print(io::IO, x::ArrowSet) = print(io, string(x))
println(io::IO, x::ArrowSet) = println(io, string(x))
show(io::IO, x::ArrowSet) = print(io, string(x))
showcompact(io::IO, x::ArrowSet) = print(io, string(x))

## ArrowSet combinators
## ====================

"Takes an param arrow of one output, and an arrow of more than one input"
function firstarrset{I1, I2, O}(param::CompositeArrow{I1, 1}, x::CompositeArrow{I2, O})
  @assert I2 > 1 "Can't partially apply if only takes one input"
  ArrowSet{I1, 1}([true; falses(I2-1)], first(param) >>> x)
end

# Deal with prim arrows
firstarrset(param::CompositeArrow, x::PrimArrow) = firstarrset(param, encapsulate(x))
firstarrset(param::PrimArrow, x::PrimArrow) = firstarrset(encapsulate(param), encapsulate(x))
firstarrset(param::PrimArrow, x::CompositeArrow) = firstarrset(encapsulate(param), x)

"infix shorthand for `firstarrset`"
|>(param::Arrow, x::Arrow) = firstarrset(param, x)

function compose{PI, PO}(arrset::ArrowSet{PI, PO}, arrow::CompositeArrow)
  ArrowSet{PI, PO}(arrset.isparam, arrset.arrow >>> arrow)
end

compose(arrset::ArrowSet, arrow::PrimArrow) = compose(arrset, encapsulate(arrow))

"Expose turns an ArrowSet into an Arrow by pulling out all the inputs of the Arrow."
expose(arrset::ArrowSet) = arrset.arrow

"Exposes the parameters of the an arrowset and puts them as contiguously as the first inputs"
untangle(arrset::Arrow) = error("unimplemented")
