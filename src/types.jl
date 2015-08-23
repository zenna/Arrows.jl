"An expression for type variales"
abstract TypeExpr{T}

"A type variable, e.g. `T`"
type TypeVar{T} <: TypeExpr{T} end

"A type after transformation, e.g. `2T`"
type TypeExprComposite{T} <: TypeExpr{T} end
