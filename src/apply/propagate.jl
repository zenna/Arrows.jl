#TODO:
# 1. How to do multiple dispatch
# 2. How to not propagate more than once
# 3. WHat kind of datastructure to propagate
# 4. Remember we might go in and out of a function
# 5. How to know if something isn't propagated

# How to ddeal with port att

"""Generic Propagation of values around a composite arrow"""
function update_propss!(to_update::Props,
                            with_p::Props,
                            dont_update::Set,
                            fail_on_conflict=True)
  for (key, value) in with_p
    if key not in dont_update
      if key in to_update && fail_on_conflict
        @assert is_equal(value, to_update[key]), "conflict %s, %s" % (value, to_update[key])
        to_update[key] = value
      end
    end
  end
end



# """
# For every port in sub_props the  data all of its connected nodes
# Args:
#     sub_props: Port Attributes restricted to a particular arrow
#     : Global Props for composition to be update
#     context: The composition
#     working_set: Set of arrows that need further propagation
# """
# function update_neigh(sub_props::Props,
#                       propss::Props,
#                       context::CompositeArrow,
#                       working_set::Set[Arrow])
#   for (port, attrs) in sub_props
#     neigh_ports = conected(port, context)
#     for neigh_port in neigh_ports
#         # If the neighbouring node doesn't have a key which I have, then it will
#         # have to be added to working set to propagate again
#         if (neigh_port.arrow != context)
#             neigh_attr_keys = [neigh_port].keys()
#             if any((attr_key not in neigh_attr_keys for attr_key in attrs.keys())):
#                 working_set.add(neigh_port.arrow)
#         update_props([neigh_port], attrs, dont_update=DONT_PROP)
#     # Update global with this port
#     update_props([port], attrs, dont_update=DONT_PROP)
#

function copy(props::Props)::Props
  _props = Props()
  for (port, attr) in propss
    for (attr_key, attr_value) in attr
      _props[port][attr_key] = attr_value
    end
  end
  _props
end

function xxx(sub_arrows, _props)
  Dict(port=>_props[port] for port in ports(sub_arrow) if port in _props)
end

"""
Propagate values around a composite arrow to determine knowns from unknowns
The knowns should be determined by the knowns, otherwise an error throws
Args:
    arr: Composite Arrow to propagate through
    state: A value of any type that is passed around during propagation
           and can be updated by sub_propagate
Returns:
    port->value map for all ports in composite arrow
"""
function propagate(arr:: CompArrow, state)::Props
  _props = copy(props)
  extract_props(comp_arrow, _props)
  updated = set(comp_arrow.get_sub_arrows())
  update_neigh(_props, _props, comp_arrow, updated)

  while len(updated) > 0
    sub_arrow = updated.pop()
    sub_props = xxx(sub_arrows, _props)

    for (pred, dispatch) in pred_dispatches(sub_arrow)
      if pred(sub_arrow, sub_props)
        new_sub_props = dispatch(sub_arrow, sub_props)
        update_neigh(new_sub_props, _props, comp_arrow, updated)
      end
    end
    if isinstance(sub_arrow, CompositeArrow)
      sub_props = xxx(sub_arrows, _props)
      new_sub_props = propagate(sub_arrow, sub_props, state)
      update_neigh(new_sub_props, _props, comp_arrow, updated)
    end
  end
  return _props
end

function propagate(arr::CompArrow)
  propagate(arr, Dict{}, )
end
