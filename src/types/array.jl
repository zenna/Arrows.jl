# ## Type Arrays: arrays of type expressions
# ## =======================================
#
# """A fixed length vector of type expressions and constants"""
# immutable FixedLenVarArray
#   typs::Tuple{Vararg{ParameterExpr}}
# end
#
# length(x::FixedLenVarArray) = length(x.typs)
# ndims(x::FixedLenVarArray) = 1
# string(x::FixedLenVarArray) = join(map(string, x.typs),", ")
#
# "A more efficient version of a FixedLenVarArray of ConstantVariables"
# immutable ConstantArray{T<:Real}
#   val::Array{T}
# end
# string(x::ConstantArray) = string(x.val)
#
# "A vector of variable length of type expressions of `len`, e.g. s:[x_i for i = 1:n]"
# immutable VarLenVarArray
#   lb::Integer
#   ub::ParameterExpr{Integer}
#   expr::ParameterExpr
# end
#
# length(x::VarLenVarArray) = x.ub
# ndims(x::VarLenVarArray) = 1
# string(x::VarLenVarArray) = string("$(string(x.expr)) for i = $(x.lb):$(string(x.ub))")
#
# "Zero dimensional Array"
# immutable Scalar
#   val::ParameterExpr
# end
#
# length(::Scalar) = 0
# ndims(::Scalar) = 0
# string(x::Scalar) = string(x.val)
#
# """Datastructures for arrays of type expressions.
# They are not not Kinds themselves; just a datastructure used by other Kinds"""
# typealias VarArray Union{FixedLenVarArray, VarLenVarArray, Scalar, ConstantArray}
# printers(VarArray)
