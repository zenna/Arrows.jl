## PortName
## ========

"Symbol name for argument (input or output) of arrow"
immutable PortName <: Variable
  name::Symbol
end

string(x::PortName) = string(x.name)

typealias VarMap Dict{Variable, Variable}
# ## Prefixing
# ## =========

"Turn a parameter `p` into `prefixp`"
prefix{T}(p::Parameter{T}, pfx::Symbol) = Parameter{T}(symbol(pfx, :_, p.name))
prefix{T}(p::ConstrainedParameter{T}, pfx::Symbol) =
  ConstrainedParameter{T}(prefix(p.param, pfx), prefix(p.constraints, pfx))
prefix(cs::ConstraintSet, pfx::Symbol) = ConstraintSet(map(i->prefix(i, pfx), cs))
prefix(c::ConstantVar, pfx::Symbol) = c
prefix{T <: TransformedParameter}(c::T, pfx::Symbol) =
  T(tuple([prefix(arg, pfx) for arg in args(c)]...))
prefix(ps::ParameterSet, pfx::Symbol) = ParameterSet([prefix(p, pfx) for p in ps])

function substitute(d::Parameter, varmap::VarMap)
  if haskey(varmap, d)
    varmap[d]
  else
    error("varmap does not contain parameter $d")
  end
end

"Constrained parameter with parameter replaced accoriding to `varmap`"
function substitute{T}(d::ConstrainedParameter{T}, varmap::VarMap)
  if haskey(varmap, d.param)
    warn("FIXME: not handling constraints")
    ConstrainedParameter{T}(varmap[d.param])
  else
    error("varmap does not contain parameter $d")
  end
end
