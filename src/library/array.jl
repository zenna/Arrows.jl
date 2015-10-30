## Components for tensor manipulation: reshaping, resizing, shuffling
## ==================================================================
#
# #TOADD
# ## clone, split, concat
# # clone(x::Vector) = (x[1],x[2])
#
#
# "Generate a dummy arrow type, remove when type system is implemented"
# function dummyarrtype(n::Integer,m::Integer)
#   warn("using dummy types, fixme")
#   @show ip = Arrows.ArrayType([symbol(:N,i) for i = 1:n]...)
#   @show op = Arrows.ArrayType([symbol(:M,i) for i = 1:m]...)
#   @show Arrows.ArrowType{1, 1}([ip], [op], [])
# end
#
# ## dimshuffle
# ## ==========
#
# # dimshuffle takes in an array of n dimensions; a pattern vector of size n,
# # and returns an array of the same size
# dimshuffle :: N pattern:[] >> N | length(pattern) = N
# dimshuffle :: N -> a:{a_i for i = 1:N}, [p_i for i = 1:N] >> {a[p_i] for i = 1:N}
# dimshuffle 3 :: {a_1, a_2, a_3}, [p_1, p_2, p_3] >> {a[p_1], a[p_2], a[p_3]}
#
# + :: N -> a:{a_i for i = 1:N}, a:{a_i for i = 1:N} >> a:{a_i for i = 1:N}
# reshape :: N, M -> p:[p_i for i = 1:N] :> a:{a_i for i = 1:M} >> b:{p_i for i = 1:N} | prod(p) == prod(a)
# reshape 2 3 :: [p_1, p_2] :> {a_1, a_2, a_3} >> {p_1, p_2}
# flatten :: ND :> [p_i...N], >> [q_i...ND] | prod(p) == prod(q)
# diagonal :: {M, M} >> {M}
#
# "Arrow for permuting dimensions with all parameters partially applied"
# immutable DimshuffleArrow <: PrimArrow{1, 1}
#   typ::Arrows.ArrowType{1, 1}
#   pattern::Vector
#   function DimshuffleArrow(pattern::Vector)
#     warn("hack, fixme for type length")
#     typ = dummyarrtype(1, length(pattern))
#     # Generate the type of the arrow based on the pattern,
#     new(typ, pattern)
#   end
# end
#
# name(a::DimshuffleArrow) = :dimshuffle
# typ(a::DimshuffleArrow) = a.typ
#
#
# """Returns a view of this tensor with permuted dimensions.
#
# dimshuffle :: n:{a b c}, (x, y, z) >> {n[x] n[y] n[z]} | X,Y,Z \in (1, 2 ,3)
#
# Typically the pattern will include the integers 0, 1, ... ndim-1,
# and any number of ‘x’ characters in dimensions where this tensor should be broadcasted.
# """
# function dimshuffle(permutation::Vector)
#   [@assert isa(x, Integer) || x == "x" for x in permutation]
#   DimshuffleArrow(permutation)
#   # arset(permutation)
# end

## Array slicing
"""slice :: [lb_i,ub_i for i = 1:n] |> {x_i for i = 1:n} >> {ub_i - lb_i + 1 for i = 1:n}
          |  {lb_i >= 1, ub_i >= lb_i, lb_i <= x_i, ub_i <= x_i for i = 1:n}"""
## Clone
## =====
immutable CloneArrow{O} <: PrimArrow{1, O}
  typ::Arrows.ArrowType{1, O}
end

"Generate an arrow which takes one input and clones it on all its `n` outputs"
function clone(n::Integer)
  @assert n >= 2 "Cannot clone input into $n outputs, $n >= 2"
  a = @shape s [x_i for i = 1:n]
  b = collect(repeated(a, n))
  atype = Arrows.ArrowType{1,n}(tuple(a,), tuple(b...), [])
  CloneArrow{n}(atype)
end

name(::CloneArrow) = :clone
typ(a::CloneArrow) = a.typ

export dimshuffle
export clone
