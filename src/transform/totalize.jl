# 1. TODO: Make modification using walk of arrow option
# 2. TODO: Add no replacing operations
#

"Replace an inverse dupl with one that takes the mean"
identity_portid_map(arr) = PortIdMap(i => i for i = 1:num_ports(arr))

# Arrow Types #
aprx_totalize(arr::Arrow) = (arr, identity_portid_map(arr))
aprx_totalize(sarr::SubArrow) = aprx_totalize(deref(sarr))

# Primitives #
aprx_totalize{I}(arr::InvDuplArrow{I}) = (aprx_inv_dupl(I), identity_portid_map(arr))
aprx_totalize(carr::CompArrow) = (aprx_totalize!(carr), identity_portid_map(carr))
aprx_totalize(carr::ASinArrow) = (ClipArrow{-1.0, 1.0}() >> carr, identity_portid_map(carr))
aprx_totalize(carr::ACosArrow) = (ClipArrow{-1.0, 1.0}() >> carr, identity_portid_map(carr))
aprx_inv_dupl(n::Integer) = MeanArrow(n)

"""Convert `arr` into one which is a total function

A function `c` is an apprximate totalization of f: X -> Y, ∀ x
  c(x) = if f(x) = ⊥
           any y ∈ Y
         else
           f(x)
         end
"""
function aprx_totalize!(arr::CompArrow)
  walk!(aprx_totalize, identity, arr)
end


# Discover that an arrow is an aprximate totalization of another arrow
# Construct error function and do compose
#


# there are a few issues
# 1. A function which totalizes another may be a CompArrow,
# 2. And therefore as it stands we cnanot dispatch on its type
# 3. The function which a function aprximates may not be unique
# 4. Say a mean arrow aprximate totalizes dinv dupl, so does f(x,y) = x
 #   but i dont want to replace every mean with one that ocmputes erro
# There's a difference between totalizes as in a function totalizes anotehr
# and totalized, as in we used this to totalize anotehr function

# So either we store this information somewhere,
# - Need some way of saying things
# - e.g. 1. This arrow aprximate totalizes anotehr arrow
#        2. Within this particular carr, this arr1 totalized this one
#        3. This arrow is an inverse of this arrow.
# Right now I am doing some of that with the type system, but that only
# Allows  us to reason about primtiives and not composites
# Moreoever as shown by example 2 a composite in one situation may have different
# Properties to anotehr
# Or we act on the untotalized graph, i.e. we do this round before the other
#
aprx_totalizes(::InvDuplArrow) = DuplArrow
aprx_error(arr::DuplArrow) = VarArrow()
# aprx_error(arr::ASinArrow) = distance to interval

function siphon(arr::Arrow)
  err = aprx_error(arr)
end

"""
Capture node_loss from every sub_arrow.

∀ sarr::SubArrow ∈ `arr`
if sarr is aprximate totalization of sarr_partial
  replace sarr with sarr

  arr = SqrtArrow() # arr(-1) = ⊥
  total_arr = Sqrt

"""
function aprx_errors!(arr::CompArrow)::CompArrow
  walk!(siphon, link_error_ports!, arr)
end

# "Non mutating `aprx_errors`"
# aprx_errors(arr::CompArrow)::CompArrow = aprx_errors(deepcopy(arr))
# aprx_errors(parr::PrimArrow) = aprx_errors!(wrap(parr))
#
#
#
# arr = SqrtArrow() # arr(-1) = ⊥
# arr_w_errors = aprx_errors!(arr)
# total_arr = aprx_totalize(arr_w_errors)
# total_arr(-2.0)
