"An expression for type variables"
abstract TypeExpr{T}

"A type variable, e.g. `T`"
immutable TypeVariable <: TypeExpr{Int}  # Size of array dimension represents a integer
  expr::Symbol
end

"A type after transformation, e.g. `2T`"
immutable TypeExprComposite <: TypeExpr{Int}
  expr::Expr
end

convert(::Type{TypeExpr}, x::Symbol) = TypeVariable(x)
convert(::Type{TypeExpr}, x::Expr) = TypeExprComposite(x)

"Type of an nd-array, each element of `s` corresponds to a dimension of the array"
immutable ArrayType
  @compat dimtypes::Tuple{Vararg{TypeExpr}}
end

ndims(a::ArrayType) = length(a.dimtypes)
ArrayType(xs...) = ArrayType(tuple(TypeExpr[convert(TypeExpr,x) for x in xs]...))
ArrayType(x) = ArrayType((convert(TypeExpr,x),))
