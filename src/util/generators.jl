struct Sampler{O}
  f
  function Sampler{O}(f) where {O}
    f() isa O || throw(ArgumentError("Sample type doesn't match iterator type"))
    new(f)
  end
end

Sampler(f::Function) = Sampler{typeof(f())}(f)

"""
    sampler(f)
An iterator that samples from f forever
"""
Base.eltype(::Type{Sampler{O}}) where {O} = O
Base.start(it::Sampler) = nothing
Base.next(it::Sampler, state) = (it.f(), nothing)
Base.done(it::Sampler, state) = false
Base.iteratorsize(::Type{<:Sampler}) = Base.IsInfinite()
Base.iteratoreltype(::Type{<:Sampler}) = Base.HasEltype()
