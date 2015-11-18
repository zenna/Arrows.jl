# ## Partial Application
# ## ===================
#
"""Partial application is the process of applying an arrow to some subset of its inputs.
Unlike full application (i.e. just call an arrow), not all the inputs are provided.
Partial application is more important in arrows than in other languages because it is
often the case that compilation targets will not support an arrow in its normal unpartially
applied form.  For example theano wants integer inputs to the convolution function conv2d
to be decided before the program is compiled.
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
"""
"A Partial Arrow is an arrow which has some of its units partially applied"
immutable PartialArrow{I, O, PA <: Arrows.PrimArrow} <: PrimArrow{I, O}
  arrow::PA
  inps::Dict{PinId, Array} # Map from index to value
  #FIXME Any type too loose, it's going to be some kind of array
  function PartialArrow(arrow::PA, inps::Dict{PinId, Array})
    @assert length(inps) > 0 "Cannot partially apply with no input"
    @assert length(inps) < ninports(arrow) "*partial* not full application"
    new{I, O, PA}(arrow, inps)
  end
end

name(pa::PartialArrow) = name(pa.arrow)
typ(pa::PartialArrow) = typ(pa.arrow)
function string{I, O}(pa::PartialArrow{I, O})
  header = "$(name(pa)) :: PartialArrow{$I,$O}"
  args = [haskey(pa.inps, i) ? size(pa.inps[i]) : "_" for i = 1:ninports(pa.arrow)]
  argstring = join(map(string, args), ", ")
  join([header, argstring, typ(pa.arrow)], "\n")
end

ArrayOrMissing = Union{_, Array}
function partial{PA <: PrimArrow}(a::PA, values::Tuple{Vararg{ArrayOrMissing}})
  @assert length(values) == ninports(a)
  @assert any(x->x==_(), values) "Can't partially evaluate if given all the inputs!"
  @assert !(all(x->x==_(), values)) "Can't have all missing arguments"
  inps = Dict{PinId, Array}()
  for i = 1:length(values)
    if isa(values[i], Array)
      inps[i] = values[i]
    end
  end
  PartialArrow{I - length(inps), noutports(a), PA}(a, inps)
end

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

# "Transform an arrowtype by putting in arrow in the pids place"
# function fix{I, O, T<:Real}(at::ExplicitArrowType{I, O}, pinid::PinId, a::Array{T})
#   # When we're updating a type we want to
#   # (i) at all levels replace the type with that types type
#   # - add constraints for any type variables
#   # - check that its a valid replacement
#
#   etyp = dimtyp(a)
#   curretyp = at.dimtype.inptypes[pinid]
#   newdimtype = if isa(curretyp.value, Parameter)
#     substitute(arrowtyp.dimtype, Dict(curretyp.value => etyp.value))
#   else
#     addconstraint(at.dimtype, curretyp.value == etyp.value)
#   end
#     ExplicitArrowType{I, O}(at.elemtype, newdimtype, at.shapetype, at.valuetype, at.constraints)
# end
