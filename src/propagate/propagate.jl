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
function propagated_ports{T}(sarr::SubArrow, sprtvals::Dict{SubPort, T})
  filter(port -> haskey(sprtvals, port), sub_ports(sarr))
end

"helper function to filter not yet processed ports"
function unpropagated_ports{T}(sarr::SubArrow, sprtvals::Dict{SubPort, T})
  filter(port -> !haskey(sprtvals, port), sub_ports(sarr))
end

"helper funtion to add values to the propagation"
function add_value!{T}(prop::Propagation, port::SubPort, value::T)
  prop.sprtvals[port] = value
  push!(prop.pending, port)
end

"helper funtion to add values to the propagation while including `sub_arrow`"
function add_value_arrow!{T}(prop::Propagation, port::SubPort, value::T)
  add_value!(prop, port, value)
  push!(prop.touched_arrows, sub_arrow(port))
end

"""This function allows the information to jump over the arrows. The idea is
  that we may provide specialised functions for the different kind of
  arrows/values. For instance, if we are propagating a shape, the behavior of a
  `MatrixMultArrow` is very different than `AddArrow` """
function propagate_through!(prop::Propagation)
  for touched in prop.touched_arrows
    selected_port = first(propagated_ports(touched, prop.sprtvals))
    value = prop.sprtvals[selected_port]
    unpropagated = unpropagated_ports(touched, prop.sprtvals)
    for port in unpropagated
      add_value!(prop, port, value)
    end
    for port in sub_ports(touched)
      check_conflict(prop, port, value)
    end
  end
  prop.touched_arrows = Set()
end

"helper function that checks conflict during the propagation"
function check_conflict{T}(prop::Propagation, port::SubPort, value::T)
  if prop.sprtvals[port] != value
    throw(DomainError(msg))
  end
end

function propagate!{T}(carr:: CompArrow,
       sprtvals::Dict{SubPort, T})::Dict{SubPort, T}
  !is_recursive(carr) || throw(DomainError())
  propagation = Propagation{T}(sprtvals)
  while !isempty(propagation.pending)
    while !isempty(propagation.pending)
      port = pop!(propagation.pending)
      value = propagation.sprtvals[port]
      for ne in neighbors(port)
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
