"Shape of an Array"
struct Shape{T <: Integer, N}
  sizes::Tuple{Vararg{T, N}}
end

"Size (shape) of an array. Can have missing elements"
@auto_hash_equals struct Size
  dims::Vector{Nullable{Int}}
  ndims_unknown::Bool
end

@invariant Size ndims_unknown ⇒ isempty(dims)

Base.getindex(sz::Size, i::Integer) = sz.dims[i]

ndims(sz::Size) = length(sz.dims)
@pre ndims !sz.ndims_unknown

function Size(dims::AbstractVector{<:Integer})
  Size([x<0 ? Nullable{Int}() : Nullable{Int}(x) for x in dims])
end

Size(dims) =  Size(dims, false)

Size(::Void) = Size(Nullable{Int}[], true)

function Size(::Vector{Union{}}) # NB: `Vector{Union{}} == typeof(collect(tuple())))`
  Size(Nullable{Int}[], false)
end

Size(t::Size) = copy(t)

function meet(size1::Size, size2::Size)
  # If either ndims unknown then return other
  if size1.ndims_unknown && size2.ndims_unknown
    size1
  elseif size1.ndims_unknown
    size2
  elseif size2.ndims_unknown
    size1
  elseif ndims(size1) != ndims(size2)
    throw(MeetError([size1, size2]))
  else
    dims = Vector{Nullable{Int}}(ndims(size1))
    for i = 1:ndims(size1)
      # Both Null => Null
      if isnull(size1[i]) && isnull(size2[i])
        dims[i] = nothing
      elseif isnull(size1[i])
        dims[i] = size2[i]
      elseif isnull(size2[i])
        dims[i] = size1[i]
      else
        get(size1[i]) == get(size2[i]) || throw(MeetError([size1[i], size2[i]]))
        dims[i] = size1[i]
      end
    end
    Size(dims)
  end
end

@pre meet !disjoint(size1, size2) "Cannot meet Size which are disjoint"

# Primitives

"Propagate shapes"
function sizeprop(arr::ArithArrow, props)::SubPropType
  szs = Size[]
  !isempty(props) && @show [collect(keys(val)) for val in values(props)]
  for prop in values(props)
    if :size in keys(prop)
      push!(szs, prop[:size])
    end
  end
  if isempty(szs)
    SubPropType()
  else
    unionsz = meet(szs...)
    SubPropType(prt.port_id => PropType(:size => unionsz) for prt in ⬧(arr))
  end
end
