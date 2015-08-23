clone(x::Vector) = (x[1],x[2])

## Primitive Functions
## ===================

"""Differentiable arrows take as input a collection of real valued arrays
 and output a collection of real valued a rray"""
immutable ArrowType{I, O}
  typevars::Vector{TypeVar{Int}}
  inptypes::Vector{TypeExpr{Int}}
  outtypes::Vector{TypeExpr{Int}}
  constraints::Vector{TypeExpr{Bool}}
end

immutable PrimFunc{I, O}
  typ::ArrowType{I, O}
  s::Symbol
end

# Unary Functions
# These unary funtions take in vectors of length 1 and return vectors of length 1
dummytyp = ArrowType{1,1}([TypeVar{Int}()], [TypeVar{Int}()], [TypeVar{Int}()], [TypeVar{Bool}()])
# unaryfunctyp = PrimFuncType([],:1, :1, [])
unaryfunctyp = dummytyp
cosfunc = PrimFunc(unaryfunctyp, :cos)
sinfunc = PrimFunc(unaryfunctyp, :sin)
tanfunc = PrimFunc(unaryfunctyp, :tan)

# Binary Functions
# binaryfunctyp = PrimFuncType([],:2, :1, [])
binaryfunctyp = dummytyp
addfunc = PrimFunc(binaryfunctyp, :+)
minusfunc = PrimFunc(binaryfunctyp, :-)

clonefunc = PrimFunc(unaryfunctyp, :clone)

# Concat
# concatfunctyp = PrimFuncType([:n, :m], (:n,:m), :(n+m), [:(n>1), :(m>1)])
concatfunctyp = dummytyp
concatfunc = PrimFunc(concatfunctyp, :concat)
