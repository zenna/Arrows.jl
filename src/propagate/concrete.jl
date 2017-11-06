"Wrapper for data passed between nodes"
struct ConcreteValue{T}
  value::T
end

function meet(x::ConcreteValue, y::ConcreteValue)
  x == y || throw(MeetError, [x, y])
  x
end

function valueprop(arr::Arrow, props::SubPropType)::SubPropType
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
    SubPropType(prt.port_id => PropType(:value => cres[i]) for (i, prt) in enumerate(◂(arr)))
  else
    SubPropType()
  end
end

valueprop(arr::SourceArrow, props::SubPropType) =
  SubPropType(1 => PropType(:value => ConcreteValue(arr.value)))
