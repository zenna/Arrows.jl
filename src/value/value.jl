"A value, corresponds to connected component of `Port`s"
abstract type Value end

ValueSet{T} = Set{T} where T <: Value

## Printing
string(v::Value) = string("Value ", sort(port_id.(sub_ports(v))))
print(io::IO, v::Value) = print(io, string(v))
show(io::IO, v::Value) = print(io, v)
