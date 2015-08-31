clone(x::Vector) = (x[1],x[2])

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

# unaryfunctyp =  ArrowType{1,1}([TypeVar{Int}()], [TypeVar{Int}()], [TypeVar{Int}()], [TypeVar{Bool}()])
# This is for a type which takes in one input vector of arbitrary length and
# returns a vector of the same length

# Option 1. Disallow untyped ports
# Opiton 2. Have a Top Type
# Option 3. Make it a parametric type
# Option 4. Have ports which take variable dimension input
# 4 is most general and elegant but omre difficult to solve for.

equal1d =  ArrowType{1,1}([ArrayType(:N)],
                          [ArrayType(:N)],
                          [])

cos1dfunc = PrimFunc(equal1d, :cos)
sin1dfunc = PrimFunc(equal1d, :sin)
tan1dfunc = PrimFunc(equal1d, :tan)

equal2d =  ArrowType{1,1}([ArrayType(:N, :M)],
                          [ArrayType(:N, :M)],
                          [])

cos2dfunc = PrimFunc(equal2d, :cos)
sin2dfunc = PrimFunc(equal2d, :sin)
tan2dfunc = PrimFunc(equal2d, :tan)

# Binary Functions
binequal1d =  ArrowType{2,1}([ArrayType(:N), ArrayType(:N)],
                             [ArrayType(:N)],
                             [])
addfunc = PrimFunc(binequal1d, :+)
minusfunc = PrimFunc(binequal1d, :-)

# # Concat
binconcat = ArrowType{2,1}([ArrayType(:N), ArrayType(:N)],
                           [ArrayType(:(N+M))],
                           [])

concatfunc = PrimFunc(binconcat, :concat)

clone1d  = ArrowType{1,2}([ArrayType(:N)],
                          [ArrayType(:N), ArrayType(:N)],
                          [])

clone1dfunc = PrimFunc(clone1d, :clone)
