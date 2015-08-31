"An expression for type variales"
abstract TypeExpr{T}

"A type variable, e.g. `T`"
immutable TypeVar <: TypeExpr{Int}
  s::Symbol
end

"A type after transformation, e.g. `2T`"
immutable TypeExprComposite <: TypeExpr{Int}
  s::Expr
end

immutable ArrayType
  s::Tuple{Vararg{TypeExpr}}
end

ndims(a::ArrayType) = length(a.s)

CoolType(x::Symbol) = TypeVar(x)
CoolType(x::Expr) = TypeExprComposite(x)

ArrayType(xs...) = ArrayType((TypeExpr[CoolType(x) for x in xs]...))
ArrayType(x) = ArrayType((CoolType(x),))
