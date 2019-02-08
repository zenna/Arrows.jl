"A value, corresponds to a connected component of `Port`s"
abstract type Value end

ValueSet{T} = Set{T} where {T <: Value}

# Printing #
string(v::Value) = string("Value ", sort(port_id.(sub_ports(v))))
show(io::IO, v::Value) = show(io, string(v))
