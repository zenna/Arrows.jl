## Primitive Functions
## ===================

"""Differentiable arrows take as input a collection of real valued arrays
 and output a collection of real valued a rray"""
immutable ArrowType{I, O}
  inptypes::Vector{ArrayType}
  outtypes::Vector{ArrayType}
  constraints::Vector{TypeExpr{Bool}}
  # function ArrowType(inptypes::Vector{ArrayType}, outtypes::Vector{ArrayType},
  #           constraints::Vector{TypeExpr{Bool}})
  #   @assert length(inptypes) == I
  #   @assert length(outtypes) == O
  #   new{I,O}(inptypes, outtypes, constraints)
  # end
end

immutable PrimFunc{I, O}
  typ::ArrowType{I, O}
  name::Symbol
end

# Unary Functions
# These unary funtions take in vectors of length 1 and return vectors of length 1
# unaryfunctyp = PrimFuncType([],:1, :1, [])

# unaryfunctyp =  ArrowType{1,1}([TypeVariable{Int}()], [TypeVariable{Int}()], [TypeVariable{Int}()], [TypeVariable{Bool}()])
# This is for a type which takes in one input vector of arbitrary length and
# returns a vector of the same length

# Option 1. Disallow untyped ports
# Opiton 2. Have a Top Type
# Option 3. Make it a parametric type
# Option 4. Have ports which take variable dimension input
# 4 is most general and elegant but omre difficult to solve for.
