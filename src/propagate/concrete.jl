"Wrapper for data passed between nodes"
struct ConcreteValue{T}
  value::T
end

"All arrows can do constant propagation and value propagation"
abinterprets(::Arrow) = [valueprop, constprop]

function meet(x::Bool, y::Bool)
  x == y || throw(MeetError, [x, y])
end

function meet(x::ConcreteValue, y::ConcreteValue)
  x == y || throw(MeetError, [x, y])
  x
end

function valueprop(arr::Arrow, props::IdAbValues)::IdAbValues
  # Does every _inport_ have the property
  # If all the inputs are known compute the function and return the output
  # @show keys.(props)
  # @show typeof(props)
  allthere = all((inprt.port_id ∈ keys(props) for inprt in ▸(arr)))
  if allthere && all(has(:value), values(props))
    # args = [prop[:value] for prop in values(props)]
    args = [props[prt.port_id][:value].value for (i, prt) in enumerate(▸(arr))]
    res = interpret(arr, args...)
    cres = ConcreteValue.(res)
    IdAbValues(prt.port_id => AbValues(:value => cres[i]) for (i, prt) in enumerate(◂(arr)))
  else
    IdAbValues()
  end
end
