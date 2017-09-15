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
end

function propagate!{T}(carr:: CompArrow,
                       sprtvals::Dict{SubPort, T})::Dict{SubPort, T}
  !is_recursive(carr) || throw(DomainError())
end

"is `carr` recursive."
function is_recursive(carr::CompArrow)::Bool
end
