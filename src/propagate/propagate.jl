"Object to keep the state of the propagation process"
mutable struct Propagation{T}
  pending::Set{SrcValue}
  value_content::Dict{SrcValue, T}
  touched_arrows::Set
  sprtvals::Dict{SubPort, T}
  function Propagation{T}(seed::Dict{SubPort, T})
    p = new{T}()
    p.sprtvals = seed
    p.pending = Set(SrcValue(sport) for sport in keys(seed))
    p.touched_arrows = Set()
    p.value_content = Dict(SrcValue(sport) => content
                          for (sport, content) in seed)
    p
  end
end
"""
Propagate values around a composite arrow.
# Arguments:
  `carr`: Composite Arrow to propagate through
      assumes `!(is_recursive(carr))`
  `sprtvals`: Mapping from `SubPort` to some value of type `T`
  `propagators`: functions

- Principles
-- Every arrow can propage one or more than one value
-- It can propagate that information to any one of its ports
-- If there is already values at those ports then some kind of conflict
  resolution is necessary
-- The propagation data can depend on different types of values at differnet
   ports
# Returns:
  port->value map for all ports in composite arrow
"""
function propagate!{T}(carr:: CompArrow,
       sprtvals::Dict{SubPort, T},
       propagators...)::Dict{SubPort, T}
  !is_recursive(carr) || throw(DomainError())
  #implements a difussion process over the network created by ports.
end

"helper function to filter already processed sports"
function propagated_sports{T}(sarr::SubArrow, prop::Propagation{T})
  filter(sport -> haskey(prop.sprtvals, sport), sub_ports(sarr))
end

"helper function to filter already processed values"
function propagated_values{T}(sarr::SubArrow, prop::Propagation{T})
  sports = propagated_sports(sarr, prop)
  Set(map(SrcValue, sports))
end

"helper function to filter not yet processed sports"
function unpropagated_sports{T}(sarr::SubArrow, prop::Propagation{T})
  filter(sport -> !haskey(prop.sprtvals, sport), sub_ports(sarr))
end

"helper function to filter not yet processed values"
function unpropagated_values{T}(sarr::SubArrow, prop::Propagation{T})
  sports = unpropagated_sports(sarr, prop)
  Set(map(SrcValue, sports))
end

"helper funtion to add values to the propagation"
function add_content!{T}(prop::Propagation{T}, sport::SubPort, content::T)
  prop.sprtvals[sport] = content
end

"helper funtion to add values to the propagation while including `sub_arrow`"
function add_content_arrow!{T}(prop::Propagation{T}, sport::SubPort, content::T)
  add_content!(prop, sport, content)
  push!(prop.touched_arrows, sub_arrow(sport))
end

"""This function allows the information to jump over the arrows. The idea is
  that we may provide specialised functions for the different kind of
  arrows/values. For instance, if we are propagating a shape, the behavior of a
  `MatrixMultArrow` is very different than `AddArrow` """
function propagate_through!(prop::Propagation)
  for sarrow in prop.touched_arrows
    selected_value = first(propagated_values(sarrow, prop))
    content = prop.value_content[selected_value]
    unpropagated = unpropagated_values(sarrow, prop)
    for value in unpropagated
      prop.value_content[value] = content
      push!(prop.pending, value)
    end
  end
  prop.touched_arrows = Set()
end

"helper function that checks conflict during the propagation"
function check_conflict{T}(prop::Propagation{T}, sport::SubPort, content::T)
  if prop.sprtvals[sport] != content
    throw(DomainError(msg))
  end
end

"helper function to propagate the content of a value to all its subports"
function propagate!{T}(value::SrcValue, prop::Propagation{T})
  content = prop.value_content[value]
  for sport in sub_ports(value)
    if haskey(prop.sprtvals, sport)
      check_conflict(prop, sport, content)
    else
      add_content_arrow!(prop, sport, content)
    end
  end
end

function propagate!{T}(carr:: CompArrow,
       sprtvals::Dict{SubPort, T})::Dict{SubPort, T}
  !is_recursive(carr) || throw(DomainError())
  propagation = Propagation{T}(sprtvals)
  while !isempty(propagation.pending)
    while !isempty(propagation.pending)
      value = pop!(propagation.pending)
      propagate!(value, propagation)
    end
    propagate_through!(propagation)
  end
  propagation.sprtvals
end


"is `carr` recursive."
function is_recursive(carr::CompArrow)::Bool
  false
end
