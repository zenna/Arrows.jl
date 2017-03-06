# Primitimve Math Arrow
# Q1. Do we need parents?\
# Shou

# I've come back and forth on thsi idea of whether functions should have identity or not
# I've struggeld with this because on the one hand be equivalent to another function# What are the implications?

# What do we gain

# Pros
# Save memory
# probably more efficient.
# ! Forget about it being a bits type
# Might be simpler
# But fundamentally we do need to be able to distinguish between two nodes
# So its possible in teh graph to have these things be distinguished
# but its not obvious how you would aatually connect them
# youd need to do some indexing based on.
# That is, a port would have to return its port_index

# Pros
# - Gain: space efficnet
# - more elegant in a way + == +
#

# Cons
# - Lose ability to take port and see directly where it is, must always know the context
# vcannot build a big global map of port to something,e e.g. abstract value or something
# cannot label port attributes (do we need to?)
#

# It's not clear in the code that we have that we need parent
# We do need ports to be distinct though....
# If it turns out we need a parent then I'll add it


# Is using location in memory a good thing? for distinguishing equivalence

# Arrow e quivalence
# When are two arrows equivalent?
# equievalence is important because we use equivalence
# 1. All arrows have a unique name
# 1. arrows are different by virtue of their location in memory
# 3. arrows are equivalent by virtue of their index in the composition
# 4.

function bin_arith_port_attrs()
  [PortAttrs(true, :x, Array{Real}),
   PortAttrs(true, :y, Array{Real}),
   PortAttrs(false, :z, Array{Real})]
end

set_parent!{A <: PrimArrow}(arr::A, c_arr::CompArrow)::A = A(c_arr)

immutable AddArrow <: PrimArrow{2, 1}
  id::Symbol
  parent::Nullable{CompArrow}
end
name(::AddArrow)::Symbol = :+
port_attrs(::AddArrow) = bin_arith_port_attrs()
AddArrow() = AddArrow(gen_id(), Nullable{CompArrow}())
AddArrow(parent::CompArrow) = AddArrow(gen_id(), parent)

convert(Arrow, ::typeof(+)) = AddArrow
lift(f::Function) = convert(Arrow, f)
function +(x::Port, y::Port)
  # Check all parent arrows are the same
  if !same((parent(p) for p in [x,y]))
    throw(DomainError())
  end

  # Find the corresponding port in this composition
  x2 = proj_port(x)
  y2 = proj_port(y)

  addarr = AddArrow()
  # Create a new arrow
  # wire them upp
end
