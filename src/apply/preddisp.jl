# Predicate Dispatch

"A predicate dispatch"
immutable PredDispatch
  pred::Function   # The predicate
  disp::Function   # The dispatch function
  refire::Function # Continue Firing
end

PropDict = Dict{Symbol, Any}

function update_prop_dict!(old_pd::PropDict, new_pd::PropDict)
  for (attr_key, attr_value) in new_pd
    if attr_key in keys(old_pd)
      if old_pd[attr_key] != attr_value
        @assert false
      end
    else
      old_pd[attr_key] = attr_value
    end
  end
  old_pd
end

Props = Dict{Port, PropDict}
