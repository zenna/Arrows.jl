## Components for tensor manipulation: reshaping, resizing, shuffling
## ==================================================================

#TOADD
## clone, split, concat
# clone(x::Vector) = (x[1],x[2])


"Generate a dummy arrow type, remove when type system is implemented"
function dummyarrtype(n::Integer,m::Integer)
  warn("using dummy types, fixme")
  @show ip = Arrows.ArrayType([symbol(:N,i) for i = 1:n]...)
  @show op = Arrows.ArrayType([symbol(:M,i) for i = 1:m]...)
  @show Arrows.ArrowType{1, 1}([ip], [op], [])
end

"Arrow for permuting dimensions with all parameters partially applied"
immutable DimshuffleArrow{T<:Integer} <: Arrows.Arrow{1, 1}
  typ::Arrows.ArrowType{1, 1}
  pattern::Vector{T}
  function DimshuffleArrow(pattern::Vector{T})
    typ = dummyarrtype(length(pattern), length(pattern))
    # Generate the type of the arrow based on the pattern,
    new{T}(typ, pattern)
  end
end

name(a::DimshuffleArrow) = :dimshuffle

"Return parameters"
parameters(x::DimshuffleArrow) = Dict(:pattern => x.pattern)

# immutable ArraySet{I, O} <: Arrow{I, O}
#   typ::ArrowSetType
# end
#
# "Evaluate an arrowset with some input to return an arrow"
# function call(arrset::ArraySet{I,O}, inp)
#   ...
# end

# """Return the array set
# dimshuffle :: @arrtype (x, y, z) :> n:{a b c} >> {n[x] n[y] n[z]} | X,Y,Z \in (1, 2 ,3)"""
# function dimshuffle()
#   typ = @arrtype (x, y, z) :> n:{a b c} >> {n[x] n[y] n[z]} | X,Y,Z \in (1, 2 ,3)
#   ArraySet{1, 1}(typ)
# end

"""Returns a view of this tensor with permuted dimensions.

dimshuffle :: n:{a b c}, (x, y, z) >> {n[x] n[y] n[z]} | X,Y,Z \in (1, 2 ,3)

Typically the pattern will include the integers 0, 1, ... ndim-1,
and any number of ‘x’ characters in dimensions where this tensor should be broadcasted.
"""
function dimshuffle{T<:Integer}(permutation::Vector{T})
  # @assert isa(x, Integer) || x == "x"
  DimshuffleArrow{T}(permutation)
  # arset(permutation)
end
