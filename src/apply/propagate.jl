
function any_shape(arr::AddArrow, props::Props)
  return true
end

function same_shape(arr::AddArrow, props::Props)
  Props(port=>Dict("shape"=>(1, 2, 3)) for port in ports(arr))
end


function predicate_dispatches(::AddArrow)
  [(any_shape, same_shape)]
end

"Given a `partition` return a mapping from elements to the cell (integer id)"
function cell_membership{T}(partition::Vector{Vector{T}})::Dict{T, Int}
  element_to_class = Dict{T, Int}()
  for (i, class) in enumerate(partition), element in class
    @assert element ∉ keys(element_to_class)
    element_to_class[element] = i
  end
  element_to_class
end

"Propagate with port partitions already defined"
function propagate(arr::CompArrow,
                   props::Props,
                   state,
                   class_to_ports::Vector{Vector{Port}},
                   port_to_class::Dict{Port, Int},
                   class_props::Vector{PropDict})
  # TODO: Think about adding optimization to do all primitives before
  arrows_to_see = sub_arrows(arr)

  "Get the property dictionary of a port, from its class"
  sub_prop_dict(port) = class_props[port_to_class[port]]

  # Main propagation loop
  while length(arrows_to_see) > 0
    sub_arrow = pop!(arrows_to_see)

    # Find attributes restricted to sub_arrow
    sub_props = Props(port=>sub_prop_dict(port) for port in ports(sub_arrow))

    # For each pred_dispatch of sub_arrow
    # TODO pred dispatch
    for (pred, dispatch) in predicate_dispatches(sub_arrow)
      if pred(sub_arrow, sub_props)
        new_sub_props = dispatch(sub_arrow, sub_props)

        # Update the associated equivalence class
        for (port, prop_dict) in  new_sub_props
          class = port_to_class[port]
          update_prop_dict!(class_props[class], prop_dict)

          # Must (re)see every sub_arrow of any port in a cell which has changed
          for port in class_to_ports[class]
            # FIXME: Just because a port has a value doesnt mean its unchanged
            if port.arrow != arr
              push!(arrows_to_see, port.arrow)
            end
          end
        end
      end
    end
  end
  unravel_equiv_class
end


"""
Propagate values around a composite arrow
Args:
    arr: Composite Arrow to propagate through
    props: A mapping from Port to Attribute Name to Attribute Valeu,
           e.g. Port0 => 'shape' => (1, 2, 3)
    state: A value of any type that is passed around during propagation
           and can be updated by sub_propagate
Returns:
    port->value map for all ports in composite arrow
"""
function propagate!(arr:: CompArrow, props::Props, state)
  updated = Set{Arrow}(sub_arrows(arr))

  # 1. Partition every edge into connected components
  class_to_ports = weakly_connected_components(arr)

  # Set up a mapping from a port to its class
  port_to_class = cell_membership(class_to_ports)

  # aggregate class attributes
  function aggregate(ports::Vector{Port})
    prop_dict = PropDict()
    for port in ports
      if port in keys(props)
        update_prop_dict!(prop_dict, props[port])
      end
    end
    prop_dict
  end

  # Propagating values of each class
  class_props = aggregate.(class_to_ports)
  propagate(arr, props, state, class_to_ports, port_to_class, class_props)
end

function copy(props::Props)::Props
  _props = Props()
  for (port, attr) in props
    _props[port] = PropDict()
    for (attr_key, attr_value) in attr
      _props[port][attr_key] = attr_value
    end
  end
  _props
end

function propagate(arr::CompArrow, props::Props)
  _props = copy(props)
  propagate!(arr, _props, Dict())
end

function propagate(arr::CompArrow)
  propagate!(arr, Props(), Dict())
end
