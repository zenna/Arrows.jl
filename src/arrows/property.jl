"""
A property that an entity (e.g. a `Port` or `Arrow` possess).

desiderata:
- A property may be existential, e.g. this port is an error port
- Or a property may take on values e.g. the name of this port is `x`
- Use hierarchies
"""
abstract type Prop end

"Set of Properties"
mutable struct Props
  namedprops::NamedTuple  # Properties
  labels::Set{DataType}   # Properties which exist or dont
end

"Empty properties"
Props() = Props(@NT()(), Set{DataType}())

labels(prps::Props) = prps.labels
Props(namedprops::NamedTuple) = Props(namedprops, Set())

"Add property `P` to `prps`"
addprop!(P::Type{<:Prop}, prps::Props) = push!(prps.labels, P)

function addprop(P::Type{<:Prop}, prps::Props)
  prps = deepcopy(prps)
  push!(prps.labels, P)
  prps
end

function setprop(prp, prps::Props)
  prps = deepcopy(prps)
  setprop!(prp, prps)
  prps
end

"Is `prp` a property in `prps`"
in(P::Type{<:Prop}, prps::Props) = P ∈ prps.labels
is(P::Type{<:Prop}) = prps -> in(P, prps)

# Properties #
"Name of something!"
struct Name <: Prop
  name::Symbol
end
name(prps::Props) = prps.namedprops.name
string(name::Name) = string(name.name)
setprop!(nm::Name, prps::Props) =
  prps.namedprops = merge(@NT(name = nm), prps.namedprops)
namei(nm::Name, i::Integer) = Name(Symbol(nm.name, i))

"In or Out?"
type Direction <: Prop
  isin::Bool
end
In() = Direction(true)
Out() = Direction(false)
setprop!(dir::Direction, prps::Props) =
  prps.namedprops = merge(@NT(direction = dir), prps.namedprops)

direction(prps::Props) = Props.namedprops.direction
isin(dir::Direction) = dir.isin
isout(dir::Direction) = !(isin(dir))
isin(prps::Props) = isin(prps.namedprops.direction)
isout(prps::Props) = isout(prps.namedprops.direction)

"Error"
abstract type Err <: Prop end
superscript(::Type{Err}) = :ᵋ
iserror(::Type{<:Prop}) = false
iserror(::Type{<:Err}) = true
in(::Type{Err}, prps::Props) = any(iserror, prps.labels)
ϵ = Err

"Id Error"
struct IdErr <: Err end
idϵ = IdErr
superscript(::Type{IdErr}) = :ⁱᵈᵋ

"Domain Error"
struct DomainErr <: Err end
domϵ = DomainErr
superscript(::Type{DomainErr}) = :ᵈᵒᵐᵋ

"Supervised Loss"
struct SupervisedErr <: Err end
supϵ = SupervisedErr
superscript(::Type{SupervisedErr}) = :ˢᵘᵖᵋ

"Parameter Property"
type Param <: Prop end
θp = Param
superscript(::Type{Param}) = :ᶿ

"Type Property"
type Typ <: Prop
  typ::Type
end
typ(prps::Props) = prps.namedprops.typ
string(typ::Typ) = string(typ.typ)
