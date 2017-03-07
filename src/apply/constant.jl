"Constant Propagation"
@enum ValueType Constant Variable

"Constant propagation"
function const_pred(arr::Arrow, )::Bool
  # If all the inputs
  extract(arr, props, :ValueType)
end

function const_refire(arr::Arrow)::Bool
  ...
end

ConstProp = PredDispatch(const_pred, const_disp, const_refire)
@register! Arrow ConstProp
