"Represents a `Value` with member `port::Port ∈ Value`"
struct SrcValue <: Value
  srcsprt::SubPort
  SrcValue(sprt::SubPort) = new(src(sprt))
end

"Source SubPort of `val`, `s::SubPort s.t. ∀ v ∈ val, src(v) == s`"
src(val::SrcValue) = val.srcsprt

hash(val::SrcValue) = hash(src(val))
parent(val::SrcValue) = parent(val.srcsprt)
isequal(v1::SrcValue, v2::SrcValue)::Bool = isequal(v1.srcsprt, v2.srcsprt)
(==)(v1::SrcValue, v2::SrcValue) = isequal(v1, v2)

"Name of value.  Should be unique within parent `CompArrow`"
name(val::SrcValue) = Symbol(:val, :_, name(src_sub_port(val)))

"Ports represented in `val`"
sub_ports(val::SrcValue)::Vector{SubPort} = [src(val), out_neighbors(src(val))...]

"Get Vector of InPort ValueSet"
in_values_vec(arr::SubArrow)::Vector{Value} =
  [SrcValue(port) for port in in_sub_ports(arr)]

in_values_vec(arr::CompArrow) = in_values_vec(sub_arrow(arr))

"Get Set of OutPort ValueSet"
out_values(arr::SubArrow)::Vector{Value} =
  [SrcValue(port) for port in  out_sub_ports(arr)]

out_values(arr::CompArrow) = out_values(sub_arrow(arr))

"`subarr` such that `value` is an output of `subarr`"
src_sub_arrow(val::Value)::SubArrow = src_sub_arrow(value.port)

"Source `SubPort` of `val`, ∀ sport ∈ val, ∃ `Link` source -> sport"
src_sub_port(val::SrcValue)::SubPort = src(val.port)

# Printing #
string(v::Value) = string("Value ", sort(port_id.(sub_ports(v))))
show(io::IO, v::Value) = print(io, v)
