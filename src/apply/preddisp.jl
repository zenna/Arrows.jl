# Predicate Dispatch

"A predicate dispatch"
immutable PredDispatch
  pred::Function   # The predicate
  disp::Function   # The dispatch function
  refire::Function # Continue Firing
end

PropDict = Dict{Symbol, Any}
typealias Props Dict{Port, PropDict}
