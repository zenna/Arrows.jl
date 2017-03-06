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

immutable AddArrow <: PrimArrow{2, 1} end
name(::AddArrow)::Symbol = :+
port_attrs(::AddArrow) = bin_arith_port_attrs()

# A possibility there is that the port_index could be wrong
#

#
# # Cons
# # It's more difficult to just say what is the vlaue at some port
#
# #FIXME: DRY
#
# function bin_arith_port_attrs()
#   [PortAttrs(true, :x, Array{Real}),
#    PortAttrs(true, :y, Array{Real}),
#    PortAttrs(false, :z, Array{Real})]
# end
#
# immutable AddArrow <: PrimArrow{2, 1}
#   name::Symbol
#   port_attrs::Tuple{PortAttrs, PortAttrs, PortAttrs}
#   function AddArrow()
#     port_attrs = bin_arith_port_attrs()
#     new(:+, port_attrs, Nullable{CompArrow}())
#   end
# end
#
# convert(Arrow, ::typeof(+)) = AddArrow
# lift(f::Function) = convert(Arrow, f)
# function +(x::Port, y::Port)
#   # Check all parent arrows are the same
#   if !same((parent(p) for p in [x,y]))
#     throw(DomainError())
#   end
#
#   # Find the corresponding port in this composition
#   x2 = proj_port(x)
#   y2 = proj_port(y)
#
#   addarr = AddArrow()
#   # Create a new arrow
#   # wire them upp
# end
#
# immutable MinusArrow <: PrimArrow{2, 1}
#   name::Symbol
#   port_attrs::Vector{PortAttrs}
#   parent::Nullable{CompArrow}
#   function AddArrow()
#     port_attrs = bin_arith_port_attrs()
#     new(:-, port_attrs, Nullable{CompArrow}())
#   end
# end
#
# immutable MulArrow <: PrimArrow{2, 1}
#   name::Symbol
#   port_attrs::Vector{PortAttrs}
#   parent::Nullable{CompArrow}
#   function MulArrow()
#     port_attrs = bin_arith_port_attrs()
#     new(:*, port_attrs, Nullable{CompArrow}())
#   end
# end
#
# immutable DivArrow <: PrimArrow{2, 1}
#   name::Symbol
#   port_attrs::Vector{PortAttrs}
#   parent::Nullable{CompArrow}
#   function DivArrow()
#     port_attrs = bin_arith_port_attrs()
#     new(:/, port_attrs)
#   end
# end
#
# # Ooptiosn 1. go on 31st 273
#
# # Ooptiosn 2. go on 5am on 1st, pay 343more.
#
# # Optio n3.
