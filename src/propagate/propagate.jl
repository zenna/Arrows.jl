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
  propagation = Propagation{T}(sprtvals)
  while !isempty(propagation.pending)
    propagation.touched_arrows = Set()
    while !isempty(propagation.pending)
      port = pop!(propagation.pending)
      value = propagation.sprtvals[port]
      for ne in neighbors(port)
          if haskey(propagation.sprtvals, ne)
              if propagation.sprtvals[ne] != value
                  throw(DomainError())
              end
          else
              propagation.sprtvals[ne] = value
              push!(propagation.pending, ne)
              push!(propagation.touched_arrows, sub_arrow(ne))
          end
      end
    end
    for touched in propagation.touched_arrows
        selected_port = propagated_ports(touched, propagation.sprtvals)[1]
        value = propagation.sprtvals[selected_port]
        unpropagated = unpropagated_ports(touched, propagation.sprtvals)
        if !isempty(unpropagated)
            for port in unpropagated
                push!(propagation.pending, port)
                sprtvals[port] = value
            end
        end
        for port in sub_ports(touched)
            if propagation.sprtvals[port] != value
                throw(DomainError(msg))
            end
        end
    end
  end
  propagation.sprtvals
end


"is `carr` recursive."
function is_recursive(carr::CompArrow)::Bool
  false
end
