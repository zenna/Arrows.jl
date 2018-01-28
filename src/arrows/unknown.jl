"An unknown arrow is an arrow whose definition is not known"
mutable struct UnknownArrow <: PrimArrow
  name::Symbol
  props::Vector{Props}
  func::Function
  function UnknownArrow(name::Symbol, props::Vector{Props})
    new(name, props)
  end
end

props(farr::UnknownArrow) = farr.props
name(farr::UnknownArrow) = farr.name

function UnknownArrow(name::Symbol, n::Integer, m::Integer)
  inprts = [Props(true, Symbol(:x_, i), Any) for i = 1:n]
  outprts = [Props(false, Symbol(:y_, i), Any) for i = 1:m]
  UnknownArrow(name, vcat(inprts, outprts))
end

function UnknownArrow(name::Symbol, innms::Vector{Symbol}, outnms::Vector{Symbol})
  inprts = [Props(true, innm, Any) for innm in innms]
  outprts = [Props(false, outnm, Any) for outnm in outnms]
  UnknownArrow(name, vcat(inprts, outprts))
end

"Construct `UnknownArrow` with sane nanes as `iprts` and `oprts`"
function UnknownArrow(name::Symbol, iprts::Vector{Port}, oprts::Vector{Port})
  # TODO: transfer type information from iprts and oprtss, not just name
  UnknownArrow(name, port_sym_name.(iprts), port_sym_name.(oprts))
end