# ## Partial Application
# ## ===================
#
# """Partial application is the process of applying an arrow to some subset of its inputs.
# Unlike full application (i.e. just call an arrow), not all the inputs are provided.
# Partial application is more important in arrows than in other languages because it is
# often the case that compilation targets will not support an arrow in its normal unpartially
# applied form.  For example theano wants integer inputs to the convolution function conv2d
# to be decided before the program is compiled.
#
# Partial application
# - Update dimension type variables, if they are type variables.
# - Generate shape types
# - Update These
# - Generate value types
# - Update these
# - Update shape type variables
# - Update value variables
#
# Take permute dims
# """
# "A Partial Arrow is an arrow which has some of its units partially applied"
# immutable PartialArrow{I, O, PA <: Arrows.PrimArrow} <: PrimArrow{I, O}
#   arrow::PA
#   inps::Dict{PinId, Any} # Map from index to value
#   #FIXME Any type too loose, it's going to be some kind of array
#   function PartialArrow(arrow::PA, inps::Dict{PinId, Any})
#     @assert length(inps) > 0 "Cannot partially apply with no input"
#     @assert length(inps) < ninports(arrow) "*partial* not full application"
#     for pinid in keys(inps) @assert 1 <= pinid <= ninports(arrow) end
#
#     # For every input you want to partially evaluate, generate the appropriate
#     # type transformers and transform the types.
#     for (pinid, v) in inps
#       dimvarmap = build_model(diminptype(arrow, pinid),
#     end
#
#     #TODO, typecheck that the value is valid
#     #two options, update the type
#     #substitute in types
#     @assert all([ for (argnum, val) in inps]
#   end
# end
#
# name(pa::PartialArrow) = name(pa.arrow)
# typ(pa::PartialArrow) = typ(pa.arrow)
#
# build_model(a::ArrayType, b::ArrayType) = ..
#
# "construct a variable map"
# build_model(a::ArrayType, b::ArrayType) = ..

## Array Types from concrete arrays
## ================================
elemtyp{T<:Real}(x::T) = ElementParam(ConstantVar(T))
elemtyp{T<:Real}(x::Array{T}) = ElementParam(ConstantVar(T))
dimtyp{T<:Real}(::T) = DimParam(ConstantVar{Integer}(0))
dimtyp{T<:Real}(x::Array{T}) = DimParam(ConstantVar{Integer}(ndims(x)))
shapetyp{T<:Real}(::T) = FixedLenVarArray(tuple())
shapetyp{T<:Real}(x::Array{T}) =
  ShapeParams(FixedLenVarArray(tuple([SMTBase.ConstantVar(t) for t in size(x)]...)))
valuetyp{T<:Real}(x::T) = ValueParams(Scalar(ConstantVar(x)))
valuetyp{T<:Real}(x::Array{T}) = ValueParams(ConstantArray(x))

# "From an arrow type"
# substitute(a::ArrowType, argnum::Int, atype::ArrayType)
#
# - take a type, e.g. an array, and an input
# - 1. find its dimtype, elemtype, shape, value
# - 2. generate constraints and do the replacement.
#
# build_model(a::DimParam, b::DimParam) = VarMap(a.value => b.value)
#
# "Transform an arrowtype by putting in arrow in the pids place"
# function ok(arrowtype::ExplicitArrowType, pinid::PinId, array)
#   etyp = elemtyp(a)
#   curretyp = eleminppintype(a, pinid)
#   vmap = varmap(q, etyp)
#   newetyp = substitute(etyp, whatever)
#
#   ArrowType
#   dtyp = dimtyp(a)
# end
#
# # fix(a::ValueParams, n::Integer) = ValueParams{T}(a.portname, fix(a.values, n))
# # function fix(a::ValueParams, model::Model)
# #   if !isfixeddims(akind) && haskey(model, length(a))
# #     fix(a, model[length(a)])
# #   else
# #     return a
# #   end
# # end
# #
# #
# # function fix{I, O}(a::ArrowType{I, O}, model::Model)
# #   newinptypes = map(m->(fix(m, model)), a.inptypes)
# #   newouttypes = map(m->(fix(m, model)), a.outtypes)
# #   # TODO handle constraints
# #   newconstraints = a.constraints
# #   ArrowType{I, O}(newinptypes, newouttypes, newconstraints)
# # end
# #
# # fix{T}(a::ShapeParams{T}, n::Integer) = ShapeParams{T}(a.portname, fix(a.dimtypes, n))
# # function fix(a::ShapeParams, model::Model)
# #   if !isfixeddims(a) && haskey(model, ndims(a))
# #     @show "got here"
# #     @show model[ndims(a)]
# #     fix(a, model[ndims(a)])
# #   else
# #     return a
# #   end
# # end
# #
# #
# # "Convert a variable length var array into a fixed length one"
# # function fix(x::VarLenVarArray, ub::Integer)
# #   # TODO: Implement for expressions
# #   typs = [Parameter(x.expr, i) for i = x.lb:ub]
# #   FixedLenVarArray(tuple(typs...))
# # end
