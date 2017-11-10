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
