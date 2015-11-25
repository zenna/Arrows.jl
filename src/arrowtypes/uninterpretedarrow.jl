
"An uninterpreted arrow is an arrow without a definition"
immutable UninterpretedArrow{I, O} <: Arrow{I, O}
  typ::ArrowType{I, O}
end
