"Size (shape) of an array. Can have missing elements"
@auto_hash_equals struct Size
  dims::Vector{Nullable{Int}}
  ndims_unknown::Bool
end

Size(dims::Tuple{Vararg{<:Int}}) = Size([dims...])

# FIXME: is this is a bad use of thre `get`
Base.get(sz::Size)::Vector{Int} = map(get, sz.dims)

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
        # @show size1
        # @show size2
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
function sizeprop(arr::Arrow, props)::IdAbValues
  szs = Size[]
  for prop in values(props)
    if :size in keys(prop)
      push!(szs, prop[:size])
    end
  end
  if isempty(szs)
    IdAbValues()
  else
    unionsz = meet(szs...)
    IdAbValues(prt.port_id => AbValues(:size => unionsz) for prt in ⬧(arr))
  end
end

function show(io::IO, sz::Size)
  ok = (i->isnull(i) ? "?" : get(i)).(sz.dims)
  ok = join(ok, ",")
  print(io, string("Size($ok)"))
end
