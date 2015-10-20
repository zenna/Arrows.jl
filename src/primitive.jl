## Primitive Functions
## ===================

immutable PrimFunc{I, O}
  typ::ArrowType{I, O}
  name::Symbol
end
