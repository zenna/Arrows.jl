"An unknown arrow is an arrow whose definition is not known"
struct UnknownArrow <: PrimArrow
  name::Symbol
  props::Vector{Props}
end

props(farr::UnknownArrow) = farr.props
name(farr::UnknownArrow) = farr.name

function UnknownArrow(name::Symbol, n::Integer, m::Integer)
  inprts = [Props(true, Symbol(:x_, i), Any) for i = 1:n]
  outprts = [Props(false, Symbol(:y_, i), Any) for i = 1:m]
  UnknownArrow(name, vcat(inprts, outprts))
end
