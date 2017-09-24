# Desiderata
# We can choose which values we want to propagate, constness, shape, value
# There's a propagation strategy
# - Which order to visit nodes (when doess it matter)
# - When to recurse into sub_arrows
#

function const_prop!(::Arrow, ::SubArrow, valprops::Dict{SubPort, T})
  if all(in_values())
end

"Resolve conflicts"
function asserteq!(sarrprops::Dict{Value, T}, props::Dict{Value, T2})

end

function resolve!(sprt_props::Dict{SubPort, T}, props::Dict{Value, T})
  valts = Dict(Value, Vector{T}) = ...
  for (val, ts) in valts
    resolve!(ts)
  end
  merge!(props)
end

"Update which sub_arrows to visit"
function update!(to_visit::Vector{SubArrow}, props::Dict{Value, T})
  # To be conservative:
  # An subarrow should be visited again if:
  # any any step, any information on any of its ports chaged

  #
end

"""
Propagate values around a CompositeArrow
# Arguments:
- `to_visit`: initial subarrows to visit (in sequence)
- `propagators`: (::Arrow, ::SubArrow, ::Dict{SubPort, T}) -> ::Dict{SubPort, T}
- `resolve!`: (T...) -> (T)
- `stop`: `::Dict{Values, T} -> Bool` will stop early if outputs true
# Returns:
- `props`: Properties
"""
function propagate!(to_visit::Vector{SubArrow},
                    propagators...;
                    props::Dict{Value, T} = Dict(),
                    resolve!::Function = asserteq,
                    stop::Function = props -> false)
  # Iterate until nothing less to visit or prematurely as ordered by `stop`
  while !isempty(to_visit) || stop(props)
    sarr = pop!(to_visit)
    for propagate in propagators
      sprt_props = propagate(deref(sarr), sarr)
      resolve!(sprt_props, props)
      update!(to_visit, props)
    end
  end
end

"Sort `sarrs` such that `PrimArrow`s come first"
prims_first(sarrs::Vector{SubArrow}) =
  sort(sarrs; lt = (l, r) -> isa(l, PrimArrow))

"Propagate, visiting prim arrows first"
propagate!(carr::CompArrow, args...; kwargs...) =
  propagate(prims_first(sub_arrows(carr)), args...; kwargs...)

# Questions?
# 1. What information might the user need to decide to stop early.
# -- If we give them props then they can get everything from there
# 2. When should we propagate an arrow.
# Assume that all proagators are purely function, therefore once a proagator has
# fired, it will not need to propagate unless it has new information
# So at a coarse level if its inputs change
# has new information.
# - Should the ouput of an arrow changing make it viable to repropagate
# -
# - Would we ever want to do anything on a port but not value val
