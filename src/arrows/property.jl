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

function Props(is_in_port::Bool, name::Symbol, typ::Type)
  dir = is_in_port ? In() : Out()
  Props(@NT(direction = dir,
            name = Name(name),
            typ = Typ(typ)))
end

labels(prps::Props) = prps.labels
Props(namedprops::NamedTuple) = Props(namedprops, Set())

"Add property `P` to `prps`"
addprop!(P::Type{<:Prop}, prps::Props)::Props = (push!(prps.labels, P); prps)

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
string(nm::Name) = string(nm.name)
setprop!(nm::Name, prps::Props) =
  prps.namedprops = merge(@NT(name = nm), prps.namedprops)

"In or Out?"
struct Direction <: Prop
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

"Lambda which adds `P` to its argument"
add!(P::Type{<:Prop}) = prps -> addprop!(P, prps)

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
struct Param <: Prop end
θp = Param
superscript(::Type{Param}) = :ᶿ

"Type Property"
struct Typ <: Prop
  typ::Type
end
typ(prps::Props) = prps.namedprops.typ
string(typ::Typ) = string(typ.typ)
