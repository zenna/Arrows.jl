module Values

using Spec
using ..ArrowMod: SubPort, AbstractArrow, SubArrow, CompArrow, ArrowRef, AbstractPort, Arrow
import ..ArrowMod
const A = ArrowMod

export Value, ValueSet, SrcValue
export in_values, out_values, all_values

"A value, corresponds to a connected component of `Port`s"
abstract type Value end

ValueSet{T} = Set{T} where {T <: Value}

# Printing
Base.string(v::Value) = string("Value ", sort(port_id.(sub_ports(v))))
Base.show(io::IO, v::Value) = show(io, string(v))

include("srcvalue.jl")          # SrcValue

end