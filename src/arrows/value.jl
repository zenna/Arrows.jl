"A connected component of `Port`s"
abstract type Value end

Values{T} = Set{T} where T<:Value

"Represents a `Value` with member `port::Port ∈ Value`"
struct RepValue <: Value
  port::PortRef
end

# FIXME: This is a bad hash!
hash(v::RepValue) = hash(v.arr)

function isequal(v1::RepValue, v2::RepValue)::Bool
  # Two values are equal if there is an edge between the port_refs
  is_linked(v1.port_ref, v2.port_ref)
end

"Which ports are represented in `value`"
function ports(value::RepValue)::Vector{Port}
  weakly_connected_component(value.arr, value.port)
end

"Get Set of InPort Values"
function in_values(arr::CompArrow)::Values
  Set(RepValue(arr, port) for port in in_ports(arr))
end

"Get Set of OutPort Values"
function out_values(arr::CompArrow)::Values
  Set(RepValue(arr, port) for port in in_ports(arr))
end

"`subarr` such that `value` is an output of `subarr`"
src_arrow(arr::CompArrow, value::Value) =
  src_arrow(arr, value.port)
