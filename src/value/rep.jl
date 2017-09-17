
"Represents a `Value` with member `port::Port ∈ Value`"
struct RepValue <: Value
  # FIXME rename sport
  port::SubPort   # FIXME: Thsi will be a lot more efficient if I choose
                  # src_sub_port(RepValue) only to be representative port
end

# FIXME: This is a bad hash!
hash(v::RepValue) = hash(parent(v.port))
parent(v::RepValue) = parent(v.port)

function isequal(v1::RepValue, v2::RepValue)::Bool
  # Two values are equal if there is an edge between the port_refs
  is_linked(v1.port, v2.port)
end

(==)(v1::RepValue, v2::RepValue) = isequal(v1, v2)

"Name of value.  Should be unique within parent `CompArrow`"
name(val::RepValue) = Symbol(:val, :_, name(src_sub_port(val)))

"Which ports are represented in `value`"
function sub_ports(value::RepValue)::Vector{SubPort}
  weakly_connected_component(value.port)
end

"Get Set of InPort ValueSet"
function in_values_vec(arr::SubArrow)::ValueSet
  Set(RepValue(port) for port in in_sub_ports(arr))
end

"Get Vector of InPort ValueSet"
function in_values_vec(arr::SubArrow)::Vector{Value}
  [RepValue(port) for port in in_sub_ports(arr)]
end

in_values_vec(arr::CompArrow) = in_values_vec(sub_arrow(arr))

"Get Set of OutPort ValueSet"
function out_values(arr::SubArrow)::ValueSet
  Set(RepValue(port) for port in  out_sub_ports(arr))
end

"Get Set of OutPort ValueSet"
function out_values(arr::SubArrow)::Vector{Value}
  [RepValue(port) for port in  out_sub_ports(arr)]
end

out_values(arr::CompArrow) = out_values(sub_arrow(arr))

"`subarr` such that `value` is an output of `subarr`"
src_sub_arrow(value::Value)::SubArrow = src_sub_arrow(value.port)

"Source `SubPort` of `val`, ∀ sport ∈ val, ∃ `Link` source -> sport"
src_sub_port(val::RepValue)::SubPort = src(val.port)
