"A value, corresponds to connected component of `Port`s"
abstract type Value end

Values{T} = Set{T} where T<:Value

"Represents a `Value` with member `port::Port ∈ Value`"
struct RepValue <: Value
  port::SubPort
end

# FIXME: This is a bad hash!
hash(v::RepValue) = hash(v.port.arrow)

function isequal(v1::RepValue, v2::RepValue)::Bool
  # Two values are equal if there is an edge between the port_refs
  is_linked(v1.port, v2.port)
end

"Which ports are represented in `value`"
function ports(value::RepValue)::Vector{Port}
  weakly_connected_component(value.arr, value.port)
end

"Get Set of InPort Values"
function in_values(arr::SubArrow)::Values
  Set(RepValue(port) for port in in_ports(arr))
end

in_values(arr::CompArrow) = in_values(sub_arrow(arr))

"Get Set of OutPort Values"
function out_values(arr::SubArrow)::Values
  Set(RepValue(port) for port in  out_ports(arr))
end

out_values(arr::CompArrow) = out_values(sub_arrow(arr))

"`subarr` such that `value` is an output of `subarr`"
src_arrow(arr::CompArrow, value::Value) = src_arrow(arr, value.port)
