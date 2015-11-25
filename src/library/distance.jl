## Distances
## =========

begin
  """
  Real >> Real
  n >> n
  (xi for i = 1:n) >> (xi for i = 1:n)
  """
  local x = VarLenVarArray(:i, 1, :n, :x)
  local xnd = Arrows.ShapeArray(ConstantVar(Real), x)
  local znd = Arrows.ShapeArray(ConstantVar(Real), FixedLenVarArray{Integer}())
  dist_type = Arrows.ExplicitArrowType{2,1}((xnd,xnd), (znd,), SMTBase.ConstraintSet())
end

"Class of arrows for primitive distance operations"
immutable DistArrow <: PrimArrow{2, 1}
  typ::ArrowType
  name::Symbol
end

DistArrow(s::Symbol) = DistArrow(dist_type, s)
typ(a::DistArrow) = a.typ
name(a::DistArrow) = a.name

## Primitive Arithmetic Arrows
## ===========================

const eucliddistarr = DistArrow(:euclid)
export eucliddistarr
