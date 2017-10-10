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
name(val::SrcValue) = Symbol(:val, :_, name(src(val)))

"Ports represented in `val`"
sub_ports(val::SrcValue)::Vector{SubPort} = [src(val), out_neighbors(src(val))...]

"Get Vector of InPort ValueSet"
in_values(aarr::AbstractArrow)::Vector{SrcValue} = SrcValue.(▹(aarr))

"Get Vector of OutPort ValueSet"
out_values(aarr::AbstractArrow)::Vector{SrcValue} = SrcValue.(◃(aarr))

"Get Vector of ValueSet"
all_values(sarr::SubArrow)::Vector{SrcValue} = SrcValue.(⬨(sarr))
