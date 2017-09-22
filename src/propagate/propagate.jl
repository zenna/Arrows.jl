"Object to keep the state of the propagation process"
mutable struct Propagation{T}
  pending::Set{SrcValue}
  value_content::Dict{SrcValue, T}
  touched_arrows::Set
  sprtvals::Dict{SubPort, T}
  carr::CompArrow
  propagator::Function
  function Propagation{T}(carr::CompArrow, seed::Dict{SubPort, T}, propagator::Function)
    p = new{T}()
    p.carr = carr
    p.sprtvals = seed
    p.pending = Set(SrcValue(sport) for sport in keys(seed))
    p.touched_arrows = Set()
    p.value_content = Dict(SrcValue(sport) => content
                          for (sport, content) in seed)
    prologue, p.propagator = propagator()
    prologue(p)
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
       propagator::Function)::Dict{SubPort, T}
  !is_recursive(carr) || throw(DomainError())
  propagation = Propagation{T}(carr, sprtvals, propagator)
  while !(isempty(propagation.pending) && isempty(propagation.touched_arrows))
    while !isempty(propagation.pending)
      value = pop!(propagation.pending)
      propagate!(value, propagation)
    end
    propagate_through!(propagation)
  end
  propagation.sprtvals
end

"check if a key is in sprtvals"
function haskey_sprvals{T}(prop::Propagation{T})
  sport -> haskey(prop.sprtvals, sport)
end

"filter sports with a boolean function"
function filter_sports{T}(sarr::SubArrow,
      prop::Propagation{T},
      f::Function)
  filter(f, sub_ports(sarr))
end

"filter values according to a boolean function"
function filter_values{T}(sarr::SubArrow,
      prop::Propagation{T},
      f::Function)
  sports = filter_sports(sarr, prop, f)
  Set(map(SrcValue, sports))
end

"filter already processed values"
function propagated_values{T}(sarr::SubArrow, prop::Propagation{T})
  filter_values(sarr, prop, haskey_sprvals(prop))
end


"filter not yet processed values"
function unpropagated_values{T}(sarr::SubArrow, prop::Propagation{T})
  filter_values(sarr, prop, !haskey_sprvals(prop))
end

"add values to the propagation"
function add_content!{T}(prop::Propagation{T}, sport::SubPort, content::T)
  prop.sprtvals[sport] = content
end

"add values to the propagation while including `sub_arrow`"
function add_content_arrow!{T}(prop::Propagation{T}, sport::SubPort, content::T)
  add_content!(prop, sport, content)
  push!(prop.touched_arrows, sub_arrow(sport))
end

"state that a value needs to propagate some content"
function add_pending!{T}(prop::Propagation{T}, value::SrcValue, content::T)
  prop.value_content[value] = content
  push!(prop.pending, value)
end

"""This function is the basic way in which content is propagated thrhough an
  arrow: all Values connected to the arrow will have the same content"""
function same_content_propagator()
  function f(sarrow::SubArrow, prop::Propagation)
    selected_value = first(propagated_values(sarrow, prop))
    content = prop.value_content[selected_value]
    unpropagated = unpropagated_values(sarrow, prop)
    foreach(value-> add_pending!(prop, value, content), unpropagated)
  end
  x->nothing, f
end

"""This function allows the information to jump over the arrows. The idea is
  that we may provide specialised functions for the different kind of
  arrows/values. For instance, if we are propagating a shape, the behavior of a
  `MatrixMultArrow` is very different than `AddArrow` """
function propagate_through!(prop::Propagation)
  f = sarrow->prop.propagator(sarrow, prop)
  foreach(f, prop.touched_arrows)
  prop.touched_arrows = Set()
end

"check conflict during the propagation"
function check_conflict{T}(prop::Propagation{T}, sport::SubPort, content::T)
  if prop.sprtvals[sport] != content
    throw(DomainError(msg))
  end
end

"propagate the content of a value to all its subports"
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

"""propagate the content of a value to all its subports,
  using the default policy: every sarrow propagate the same content to
  each of its values"""
function propagate!{T}(carr:: CompArrow,
       sprtvals::Dict{SubPort, T})::Dict{SubPort, T}
  !is_recursive(carr) || throw(DomainError())
  propagate!(carr, sprtvals, same_content_propagator)
end


"is `carr` recursive."
function is_recursive(carr::CompArrow)::Bool
  false
end
