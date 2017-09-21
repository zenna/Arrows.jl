"Object to keep the state of the propagation process"
mutable struct Propagation{T}
  pending::Vector{SubPort}
  touched_arrows::Set
  sprtvals::Dict{SubPort, T}
  function Propagation{T}(seed::Dict{SubPort, T})
    p = new{T}()
    p.sprtvals = seed
    p.pending = collect(keys(seed))
    p.touched_arrows = Set()
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

"helper function to filter already processed ports"
function propagated_sports{T}(sarr::SubArrow, sprtvals::Dict{SubPort, T})
  filter(sport -> haskey(sprtvals, sport), sub_ports(sarr))
end

"helper function to filter not yet processed ports"
function unpropagated_sports{T}(sarr::SubArrow, sprtvals::Dict{SubPort, T})
  filter(sport -> !haskey(sprtvals, sport), sub_ports(sarr))
end

"helper funtion to add values to the propagation"
function add_value!{T}(prop::Propagation, sport::SubPort, value::T)
  prop.sprtvals[sport] = value
  push!(prop.pending, sport)
end

"helper funtion to add values to the propagation while including `sub_arrow`"
function add_value_arrow!{T}(prop::Propagation, sport::SubPort, value::T)
  add_value!(prop, sport, value)
  push!(prop.touched_arrows, sub_arrow(sport))
end

"""This function allows the information to jump over the arrows. The idea is
  that we may provide specialised functions for the different kind of
  arrows/values. For instance, if we are propagating a shape, the behavior of a
  `MatrixMultArrow` is very different than `AddArrow` """
function propagate_through!(prop::Propagation)
  for touched in prop.touched_arrows
    selected_sport = first(propagated_sports(touched, prop.sprtvals))
    value = prop.sprtvals[selected_sport]
    unpropagated = unpropagated_sports(touched, prop.sprtvals)
    for sport in unpropagated
      add_value!(prop, sport, value)
    end
    for sport in sub_ports(touched)
      check_conflict(prop, sport, value)
    end
  end
  prop.touched_arrows = Set()
end

"helper function that checks conflict during the propagation"
function check_conflict{T}(prop::Propagation, sport::SubPort, value::T)
  if prop.sprtvals[sport] != value
    throw(DomainError(msg))
  end
end

function propagate!{T}(carr:: CompArrow,
       sprtvals::Dict{SubPort, T})::Dict{SubPort, T}
  !is_recursive(carr) || throw(DomainError())
  propagation = Propagation{T}(sprtvals)
  while !isempty(propagation.pending)
    while !isempty(propagation.pending)
      sport = pop!(propagation.pending)
      value = propagation.sprtvals[sport]
      for ne in neighbors(sport)
        if haskey(propagation.sprtvals, ne)
          check_conflict(propagation, ne, value)
        else
          add_value_arrow!(propagation, ne, value)
        end
      end
    end
    propagate_through!(propagation)
  end
  propagation.sprtvals
end


"is `carr` recursive."
function is_recursive(carr::CompArrow)::Bool
  false
end
