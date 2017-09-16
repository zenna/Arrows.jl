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
-- If there is already values at those ports then some kind of conflict resolution
   is necessary
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

function propagate!{T}(carr:: CompArrow,
                       sprtvals::Dict{SubPort, T})::Dict{SubPort, T}
  !is_recursive(carr) || throw(DomainError())
  to_propagate = collect(keys(sprtvals))
  while !isempty(to_propagate)
    touched_arrows = Set()
    while !isempty(to_propagate)
      port = pop!(to_propagate)
      value = sprtvals[port]
      for ne in neighbors(port)
          if haskey(sprtvals, ne)
              if sprtvals[ne] != value
                  throw(DomainError())
              end
          else
              sprtvals[ne] = value
              push!(to_propagate, ne)
              push!(touched_arrows, sub_arrow(ne))
          end
      end
    end
    for touched in touched_arrows
        selected_port = propagated_ports(touched, sprtvals)[1]
        value = sprtvals[selected_port]
        unpropagated = unpropagated_ports(touched, sprtvals)
        if !isempty(unpropagated)
            for port in unpropagated
                push!(to_propagate, port)
                sprtvals[port] = value
            end
        end
        for port in sub_ports(touched)
            if sprtvals[port] != value
                throw(DomainError(msg))
            end
        end
    end
  end
  sprtvals
end


"is `carr` recursive."
function is_recursive(carr::CompArrow)::Bool
  false
end
